## <h1 align="center"> BurpSuite Professional </h1>
<p align="center"> Burp Suite Professional is the web security tester's toolkit of choice. Use it to automate repetitive testing tasks - then dig deeper with its expert-designed manual and semi-automated security testing tools. Burp Suite Professional can help you to test for OWASP Top 10 vulnerabilities - as well as the very latest hacking techniques.
</p>

<br></br>

- ### Requirements:

      sudo apt update
    
      sudo apt install curl git wget openjdk-23-jdk openjdk-23-jre
    
                                           
- ### Auto Install:

      sudo -i

      curl https://raw.githubusercontent.com/xiv3r/Burpsuite-Professional/main/install.sh | sudo bash


- ### Run (root)

      burpsuitepro


- ### NoneRoot Terminal:

      burpsuitepro

    (New terminal CTRL + N)
  
      java -jar /usr/share/burpsuitepro/loader.jar


- ### Update [optional]

      sudo -i

      curl https://raw.githubusercontent.com/xiv3r/Burpsuite-Professional/main/update.sh | sudo bash

- ### Switching Java Version

      update-alternatives --config java

- ### Setup License:

  

https://github.com/xiv3r/Burpsuite-Professional/assets/117867334/c25831a4-68a2-44ee-b6dd-5ff18165f340


      
- Note: Copy the license from loader to the burpsuite > manual activation > copy burpsuite request key to loader request >  copy response key to the burpsuite
     

