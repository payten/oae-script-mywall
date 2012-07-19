#!/usr/bin/env jruby

require 'net/http'
require 'rubygems'
require 'json'
require 'markaby'
#require 'random'

@dry_run = true

@url = URI.parse("http://localhost:8080")
@user = "admin"
@pass = "admin"

puts "-- This is a script to create a My Wall dashboard for a user"
puts "-- for use with Sakai OAE 1.3


if ARGV.size === 1
  @userid = ARGV[0]
else
  @userid = ["payten"]
end

def get_json(path, raw = false)
    Net::HTTP.start(@url.host, @url.port) do |http|
		#print "-- GET: #{path}\n"
        req = Net::HTTP::Get.new(path)
        req.basic_auth @user, @pass
        response = http.request(req)
		
		if response.code.to_s === "404" then
			return nil
		end
		#puts response
		#puts response.body
        if raw
            return response.body()
        else
            return JSON.parse(response.body())
        end
    end
end

def post_json(path, json)
  if @dry_run then
    "POST: #{path}"
  else
    prim_post(path, {
		  ":content" => json,
		  ":operation" => "import",
		  ":replace" => "true",
		  ":replaceProperties" => "true",
		  ":contentType" => "json"
	  })
  end
end

def prim_post(path, formData) 
	Net::HTTP.start(@url.host, @url.port) do |http|
        req = Net::HTTP::Post.new(path)
        req.basic_auth @user, @pass
		    req.add_field("Referer", "#{@url.to_s}/dev")
        req.set_form_data(formData)

        return http.request(req)
    end
end

def generateWidgetId()
	"id" + (1_000_000 + rand(10_000_000 - 1_000_000)).to_s	
end

def all_users()
    page = 0
    while true
        result = get_json("/var/search/users-all.json?page=#{page}")

        if result['results'].empty?
            break
        end

        result['results'].each do |result|
            yield result['rep:userId']
        end
        page += 1
    end	
end





def do_stuff
	#puts "*** Update account prefs for all users:\n"
	#all_users() do |userid|	
		print "\n* Looking at: #{@userid}\n"
		# get user's pub structure /~userid/public/pubspace
		pubspace = get_json("/~#{@userid}/public/pubspace.infinity.json")
		
		#puts pubspace
		if pubspace.nil?
			puts "user hasn't logged in yet! they'll get the structure set once they login."
			next
		end
				
		# insert the wall into this structure
		pubstructure = JSON.parse(pubspace["structure0"])
		
		if pubstructure.has_key?("wall") then
		  user_had_wall_already = true
		  puts "user has a wall... update it"
		  wall_id = pubstructure["wall"]["_ref"]
		  htmlblock_id = pubspace["#{wall_id}"]["rows"]["__array__0__"]["columns"]["__array__0__"]["elements"]["__array__0__"]["id"]
		  dashboard_id = pubspace["#{wall_id}"]["rows"]["__array__0__"]["columns"]["__array__0__"]["elements"]["__array__1__"]["id"]
	  else
	    puts "no wall for user... create it"
	    wall_id = generateWidgetId()
  		htmlblock_id = generateWidgetId()	    
  		dashboard_id = generateWidgetId()
	  end		
		
		pubstructure["wall"] = {
			"_title" => "__MSG__USER_PUBLIC_DASHBOARD_TITLE__",
			"_altTitle"=> "__MSG__USER_PUBLIC_DASHBOARD_ALT_TITLE__",
			"_order"=> -1,
			"_view"=> "private",
			"_canEdit"=> true,
			"_reorderOnly"=> false,
			"_nonEditable"=> true,
			"_ref"=> "#{wall_id}",
			"main"=> {
				"_ref"=> "#{wall_id}",
				"_order"=> 0,
				"_title"=> "__MSG__USER_PUBLIC_DASHBOARD_TITLE__"
			}
		};
		pubspace["#{wall_id}"] = {    
      "#{htmlblock_id}" => {
        'htmlblock' => {
          'content' => "<div class='fl-force-right dashboard-admin-actions' style='display:none;'><button type='button' class='s3d-button s3d-margin"+
    					"-top-5 s3d-header-button s3d-header-smaller-button dashboard_change_layout' dat"+
    					"a-tuid='#{dashboard_id}'>__MSG__EDIT_LAYOUT__</button><button type='button' class='s3d-button "+
    					"s3d-margin-top-5 s3d-header-button s3d-header-smaller-button dashboard_global_a"+
    					"dd_widget' data-tuid='#{dashboard_id}'>__MSG__ADD_WIDGET__</button></div><div class='s3d-conte"+
    					"ntpage-title'>__MSG__USER_PUBLIC_DASHBOARD_TITLE__</div><div id='widget_dashboard_#{dashboard_id}' class='widget_inline'></div>"
          }
        },
        'rows' => {
          '__array__0__' => {
            'id' => "#{generateWidgetId()}",
            'columns' => {
              '__array__0__'=> {
                'width' => 1,
                'elements' => {
                  '__array__0__' => {
                    'id' => "#{htmlblock_id}",
                    'type' => 'htmlblock'
                  },
                  '__array__1__' => {
                    'id' => "#{dashboard_id}",
                    'type' => "dashboard"                      
                  }
                }
              }
            }              
          }
        }
		};
		
		# don't overwrite existing dashboard
		unless user_had_wall_already
		  text_widget_id = generateWidgetId()
		  comment_widget_id = generateWidgetId()
		  googlemaps_widget_id = generateWidgetId()
		
    	pubspace["#{wall_id}"]["#{dashboard_id}"] = {
    		"dashboard"=> {
    			"layout"=> "dev",
    			"columns"=> {
    				"column1"=> {
                "__array__0__" => {
     				      "name" => "text",
       				    "uid"  => "#{text_widget_id}",
       				    "visible" => "block"
       				  },
                "__array__1__" => {
     				      "name" => "comments",
       				    "uid"  => "#{comment_widget_id}",
       				    "visible" => "block"
       				  },
     				},
    				"column2"=> {
              "__array__0__" => {
                "name" => "googlemaps",
                "uid"  => "#{googlemaps_widget_id}",
                "visible" => "block"
              }
    				}
    			}
    		}
    	}
    	
    	pubspace["#{text_widget_id}"] = {
    	  "text" => {
    	    "data" => {
    	      "sakai:indexed-fields" => "text",
            "sling:resourceType:" => "sakai/widget-data",
            "text" => "Tell people who you are by writing a few sentences to describe your academic interests, goals, and background.",
            "title" => "About Me"
  	      }
      	}
    	}
    	
      pubspace["#{googlemaps_widget_id}"] = {
    	  "googlemaps" => {
          "lat" => 40.7308803,
          "lng" => -73.9973273,
          "maphtml" => "Washington Square Park, 1 Washington Square N, New York, NY 10003, USA",
          "mapinput" => "Washington Square Park, New York, NY, United States",
          "mapzoom" => 15,
          "sakai:indexed-fields" => "mapinput,maphtml",
          "sling:resourceType" => "sakai/widget-data"
      	}
    	}    	
	  end
		
		pubspace["structure0"] = JSON.generate(pubstructure)
		#puts JSON.generate(pubspace["#{wall_id}"])
		
		# post the updated structure back to user's pubstructure url
		print "update user's pubspace: "
		response = post_json("/~#{@userid}/public/pubspace", JSON.generate(pubspace))
		print response
		#puts response.body
		# that should do it!
		print "\n"
	#end
end


do_stuff