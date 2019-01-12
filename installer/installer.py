import urllib.request
import os
from os.path import expanduser

home = expanduser("~")
opensapi_folder = os.path.join(home, ".opensapi")

print("Welcome to OpenSAPI")
print("A project aiming to bring Microsoft SAPI to linux for use in Accessibility technologies like Orca.")
print("")
print("Copyright NicklasMCHD (Nicklas T) - homepage: https://github.com/NicklasMCHD/OpenSAPI.")
print("")
print("This script will download and install the OpenSAPI project unto your computer.")
print("Creating file structure for installer.")
try:
	os.mkdir(opensapi_folder)
except:
	pass

	os.chdir(opensapi_folder)

print("Downloading required components: ", end="")
urllib.request.urlretrieve("https://raw.githubusercontent.com/NicklasMCHD/OpenSAPI/master/installer/osapi.run", os.path.join(opensapi_folder, "osapi.run"))
print("Done")

print("Running setup script.")
os.system("./osapi.run")
print("Done")
