Bash Scripts (Generated for: Ubuntu Maverick)
=============================================

## ubuntu-to-life.sh
a simple script which when run brings a new fresh installation of ubuntu to life, by running a combination of the bash scripts in this repo, one after the other.
Currently, it first installs ubuntu basic programs and packages, then checks for an ATI driver and installs it, if needed.  
It then installs: *RVM + Rails + Apache + Passenger + MySQL + Git + Eclipse* on my Ubuntu Maverick.  
Finally, installs a local *Redmine* instance, as a cherry-on-the-top.  
Can be re-run more than once, without fail, to always keep all these packagesb updated, and clean. 

### ati-driver-install.sh
checks, and if required, downloads and installs the ATI driver

### install-tracks.sh
installs a tracks instance (uses: webrick as a server, requires: RVM + other libraries)  
(run web-dev-install.sh first to ensure dependencies are met)
This script also tries to setup Passenger to work with this tracks instance (+ mod_proxy), if needed. ;)
This script requires RVM (currently, user-based-installs) along with a Ruby 1.8.7 install (see web-dev-install.sh)
uses:
`./install-tracks.sh uninstall` uninstall tracks from a directory
`./install-tracks.sh defaults` run installer with default parameters
add a second parameter as dot ".", if you want to INSTALL tracks in current directory itself, else you will be asked.
`./install-tracks.sh defaults .` or `./install-tracks.sh .`

### install-redmine.sh
same as above, but rather install Redmine

### ubuntu-post-install.sh
some useful ubuntu after-setup package installations..

### uninstall-all-gems.sh
uninstalls all gems from the current RubyGems environment.  
RVM equivalent: rvm gemset empty <gemset-name>

### web-dev-install.sh
an easy to use script to generate my web development environment on Ubuntu (for future installations)  
only advised for testing purposes, unless you go through the code yourself.  
it works for me. but haven't tested it on more than one installation.  
*RVM + Rails + Apache + Passenger + MySQL + PHP + Git + Eclipse*  
Note.. Eclipse plugins: RDT and PDT need to be installed, manually :(

---

#### notes
The above scripts were written to help me quickly build a Ubuntu installation (if required in future), and they just work for me.  
I provide no guarantees on the use of these scripts whatsoever.. You can, however, use them for testing-purposes or building your own scripts.  
  
Regards,  
Nikhil Gupta
