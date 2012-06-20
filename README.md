oae-script-mywall
=================

Ruby script to generate a dashboard "My Wall" for a specified userid.

--

Configuration:

At the top of the create_wall.rb file, please set your OAE environment URL and admin uid/pw:

@url

@user

@pass

By default this script won't do anything!  There's a variable @dry_run defeaulted to true.  This switch will allow for a "dry run" to first check the userid's existence, connectivity, etc.

Once confident... you can switch @dry_run = false 

Please note:  You can rerun this script on a user - but be aware you may overwrite existing widgets on the user's dashboard.

--

Running the Script:

Like all the other OAE ruby scripts, this script requires ruby-1.8.7

If running rvm:

=> rvm install ruby-1.8.7

=> rvm use ruby-1.8.7

Currently, the script does one user at a time.  To run against a userid "payten":

=> ruby create_wall.rb payten

--

Please note the "My Wall" will only work in conjunction with OAE patches as deployed in NYU's 3akai-ux master branch (http://github.com/nyuatlas/3akai-ux).

AND!! I've also combined the patch into https://github.com/payten/3akai-ux/tree/mywallpatch - it's build on the managed project's 1.2.0 branch :)


