![Screenshot_20240725_172229-1](https://github.com/user-attachments/assets/7ec02357-e399-43b2-8355-6a330e51bd30)

# <h1 align="center"> Burpsuite Professional v2024 latest </h1>

<p align="center"> Burp Suite Professional is the web security tester's toolkit of choice. Use it to automate repetitive testing tasks - then dig deeper with its expert-designed manual and semi-automated security testing tools. Burp Suite Professional can help you to test for OWASP Top 10 vulnerabilities - as well as the very latest hacking techniques. Advanced manual and automated features empower users to find lurking vulnerabilities more quickly. Burp Suite is designed and used by the industry's best.</p>

<h1 align="center">

[Overview](https://portswigger.net/burp/pro)
 </h1>
 
<br></br>

<h1 align="center"> Linux Installation </h1>

<br></br>

- ### Requirements:

      sudo apt update
    
      sudo apt install curl git wget openjdk-17-jdk openjdk-17-jre openjdk-23-jdk openjdk-23-jre -y
    
                                           
- ### Auto Install (root)

      curl https://raw.githubusercontent.com/xiv3r/Burpsuite-Professional/main/install.sh | sudo bash

- ### Run(root)

      burpsuitepro


- ### NoneRoot Install

      java -jar /usr/share/burpsuitepro/loader.jar
  
    (New terminal CTRL + N)

- ### Run: `burpsuitepro`


- ### Update [optional]

      curl https://raw.githubusercontent.com/xiv3r/Burpsuite-Professional/main/update.sh | sudo bash

- ### Change Java Version

      sudo update-alternatives --config java
  
- ### Setup License:

https://github.com/xiv3r/Burpsuite-Professional/assets/117867334/c25831a4-68a2-44ee-b6dd-5ff18165f340

Note: Copy the license from loader to the burpsuite > manual activation > copy burpsuite request key to loader request >  copy response key to the burpsuite

- ### Create a Launcher

     right click desktop and create launcher

<img width="500" height="500" src="https://github.com/xiv3r/Burpsuite-Professional/blob/main/Launcher.jpg">


     
# <h1 align="center"> Windows Installation: </h1>

<br>


   
- Make a `Burp` directory name in `C Drive` for faster access.

- Download [install.ps1](https://codeload.github.com/xiv3r/Burpsuite-Professional/zip/refs/heads/main) and extract move the file inside to `C:\Burp`

- Open `Powershell` as administrator and execute below command to set Script Execution Policy.


      Set-ExecutionPolicy -ExecutionPolicy bypass -Scope process

- Inside PowerShell go to `cd C:\Burp`

- Now Execute `install.ps1` file in Powershell to Complete Installation.

      ./install.ps1
 
- Change the icon of `Burp-Suite-Pro.vbs` to the given icon 

- Create a shortcut to Desktop. Right Click over `Burp-Suite-Pro.vbs` Go to Shortcut tab, and below there is `Change Icon` tab

- Click there and choose the `burp-suite.ico` from `C:\Burp\`

   ![image](https://user-images.githubusercontent.com/29830064/230825172-16c9cfba-4bca-46a4-86df-b352a4330b12.png)

- For Start Menu Entry, copy `Burp-Suite-Pro.vbs` file to 

      C:\ProgramData\Microsoft\Windows\Start Menu\Programs\

<details><summary>Credits:</summary>
      
* loader.jar 👉 [h3110w0r1d-y](https://github.com/h3110w0r1d-y/BurpLoaderKeygen)
* Modified from [cyb3rzest](https://github.com/cyb3rzest/Burp-Suite-Pro)
</details>

