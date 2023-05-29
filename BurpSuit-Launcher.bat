:: BurpSuit loader script by Xiv3r

@echo off

COLOR 9f

MODE con:cols=90 lines=15


:: BurpSuite Professional launcher

java --illegal-access=permit -Dfile.encoding=utf-8 -javaagent:"C:\Users\AppData\Local\Programs\BurpSuitePro-2022.8.5\loader.jar" -noverify -jar "C:\Users\AppData\Local\Programs\BurpSuitePro-2022.8.5\burpsuite_pro_v2022.8.5.jar"

CLS
