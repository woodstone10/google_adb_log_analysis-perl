# An Efficient Log Analysis with Automated and Colored ADB Filter

ADB log is collected from Android logging system (adb logcat), and it has a plain text format (.log is file extension) with several types, ex, system, event, main, kernel, radio, and so on. Through ADB, Android system can be debugged. In radop perspective, from ADB logs, we can check the status of a device such as voice and data registration state in radio log. Also, Android protocols (implemented in Android, ex, IMS, VoLTE, data, etc) behaviors can be checked in main log. In addition, there is a trace of subsystem (ex, Qualcomm modem) crash and thermal mitigation in kernel log. 

Finding keyword in ADB is the process of analysis so, keyword book is managed as data base. The difficult to ADB analysis is finding needful and necessary string on heap of texts. AdbFilter shows essential messages extracted from ADB logs to help you look into Android ADB logs by filtering with keywords. In general, we search string using a text editor such as Notepad++ and UltraEdit when finding keyword among ADB text files. There is also commercial tool (ex, TailExpert with GUI interface) and LG owned SELF for IMS analysis. AdbFilter is tiny and fast tool to show our keywords only without GUI using perl software (it is generally installed on your laptop for regular expression in QXDM). AdbFilter is designed for processing of multiple ADB files. The result of run of AdbFilter is that AdbFilter.txt file which shows filtered ADB messages in radio perspective throughout all ADB logs in the same folder. 

Keyword will be updated continuously case by case by adding keyword book database (also upon your request). In v0.2, the graph of LTE/NR RSRP and graph of Data RAT are supported. In future, AdbFilter has a plan to provide the graph for RSRP/RSRQ and call flow chart.

Required software
- Perl software is required (Recommend Strawberry perl)
- Strawberry perl: http://strawberryperl.com/ Need to install GD::Graph
  Install GD::Graph in Strawberry perl: Windows >Strawberry Perl >CPAN Client >install GD::Graph
  ![image](https://user-images.githubusercontent.com/77954837/114700790-e8031400-9d5c-11eb-8eb4-0a74c3ab1a17.png)
- Notepad++ is required (download: https://notepad-plus-plus.org/downloads/)

How to use
- Step.1: copy and past AdbFilter.pl to the target ADB folder (ex, logger folder from log service)
- Step.2: run AdbFilter.pl 
- Step.3: open AdbFilter.txt with Notepad++
- Step.4: Language > ADB in Notepad++ (optional for your view)
*	Please see pictures in Appendix. How to Use it and Appendix. Load ADB.xml in Notepad++ for details


Subsystem (modem) crash
![image](https://user-images.githubusercontent.com/77954837/114700858-05d07900-9d5d-11eb-81aa-048b0f018473.png)

RILD died
![image](https://user-images.githubusercontent.com/77954837/114700871-0bc65a00-9d5d-11eb-9b0b-523fe993b556.png)

LTE lost (voice fallback to 1x and LTE data no service)
![image](https://user-images.githubusercontent.com/77954837/114700886-108b0e00-9d5d-11eb-8fae-daefc96dee86.png)

No service (ex, LTE rejected from the network)
![image](https://user-images.githubusercontent.com/77954837/114700903-184ab280-9d5d-11eb-93e4-9866162be6c2.png)

Handover between VoLTE and VoWiFi 
![image](https://user-images.githubusercontent.com/77954837/114700912-1da7fd00-9d5d-11eb-891c-9738862f0c63.png)

VoLTE call failure (ex, SIP casue with 503)
![image](https://user-images.githubusercontent.com/77954837/114700935-239dde00-9d5d-11eb-8c65-9765df1fcc29.png)

VoLTE call drop (RTP-RTCP timeout)
![image](https://user-images.githubusercontent.com/77954837/114700954-28629200-9d5d-11eb-9afe-762e7ace1a13.png)

Thermal mitigation
![image](https://user-images.githubusercontent.com/77954837/114700971-2e587300-9d5d-11eb-9268-da50e9aaaa46.png)

RSRP graph
You will see “NrRSRP.gif” and “LteRSRP.gif” since run of AdbFilter. In graph, RSRP -150 is displayed for invalid value (ex, in case of OOS).
![image](https://user-images.githubusercontent.com/77954837/114700990-357f8100-9d5d-11eb-8a5f-977d364cd6a0.png)
![image](https://user-images.githubusercontent.com/77954837/114701019-3d3f2580-9d5d-11eb-940d-aac4502b9bef.png)

RAT graph
You will see “DataRAT.gif” since run of AdbFilter. Y-label is enum table of Android. 
![image](https://user-images.githubusercontent.com/77954837/114701040-43350680-9d5d-11eb-95f2-ea689000b09c.png)



