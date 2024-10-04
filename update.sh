#!/bin/bash

   # Remove old files
   echo 'Removing Old Files'
   sudo rm -rf Burpsuite-Professional
   sudo rm -rf /bin/burpsuitepro
   curl https://raw.githubusercontent.com/xiv3r/Burpsuite-Professional/refs/heads/main/install.sh | sudo sh
