###########################################################################################
#
# AdbFilter.py
#
# General description about Google Android ADB log:
# ADB  log is collected from Android logging system (adb logcat), and it has a plain text format (.log is file extension) 
# with several types, ex, system, event, main, kernel, radio, and so on. 
# Through ADB, Android system can be debugged. 
# In radop perspective, from ADB logs, we can check the status of a device such as voice and data registration state in radio log. 
# Also, Android protocols (implemented in Android, ex, IMS, VoLTE, data, etc) behaviors can be checked in main log. 
# In addition, there is a trace of subsystem (ex, Qualcomm modem) crash and thermal mitigation in kernel log. 
# Finding keyword in ADB is the process of analysis so, keyword book is managed as data base. 
# The difficult to ADB analysis is finding needful and necessary string on heap of texts. 
# AdbFilter shows essential messages extracted from ADB logs to help you look into Android ADB logs by filtering with keywords. 
# In general, we search string using a text editor such as Notepad++ and UltraEdit when finding keyword among ADB text files. 
# AdbFilter is tiny and fast tool to show our keywords only without GUI using perl software 
# (it is generally installed on your laptop for regular expression in QXDM). 
# AdbFilter is designed for processing of multiple ADB files. 
# The result of run of AdbFilter is that AdbFilter.txt file which shows filtered ADB messages in radio perspective throughout all ADB logs in the same folder. 
# Keyword will be updated continuously case by case by adding keyword book database (also upon request). 
#
# About this software:
# This is sample code for Google Android ADB automated parsing tool
# Automated extraction specific strings from Google Android ADB logs (text format)
# Extracted strings are printed on AdbFilter.txt
# In addition, Graphs are provided such as RSRP, RAT change, ARFCN, and so on
# In addition, KML (GoogleEarth) file is generated automatically with GPS information
# More features can be added in this manner and it will be updated
#
# How to use it:
# Step.1 copy and paste onto log folder
# Step.2 run this perl file (Perl program installation pre-required)
#
# Pre-install required:
# 1. Perl (Strawberry perl: http://strawberryperl.com/)
# 2. GD::Graph (Windows >Strawberry Perl >CPAN Client >type "install GD::Graph")
# 3. Notepad++ (download: https://notepad-plus-plus.org/downloads/)
#
# ADB.xml:
# If you open AdbFilter.txt with Notepad++,
# load ADB.xml on Notepad++ and select language as ADB
# It will help easy to see ADB log with color legend
#
#
# Created by Jonggil Nam
# https://www.linkedin.com/in/jonggil-nam-6099a162/ | https://github.com/woodstone10 | woodstone10@gmail.com | +82-10-8709-6299 
###########################################################################################

#!/apps/perl/bin
$| = 1; 
use strict;
use File::Basename;
use File::stat;
use Term::ANSIColor qw(:constants);
use Cwd;
use GD::Graph::lines;
use Win32::OLE::Variant;
use Win32::OLE::NLS qw(:LOCALE :DATE);
use Win32::OLE::NLS qw(:LOCALE :TIME);

my $VOICE_REGISTRATION_STATE; my $DATA_REGISTRATION_STATE; my $OPERATOR;
my $GET_CURRENT_CALLS;
my $LTE_NETWORK_INFO;
my $IMS_PREF_STATUS_IND;
my $NET_SUB_TYPE;
my $Broadcasting_ServiceState;
my @DataProfile = {my $DataProfile0, my $DataProfile1, my $DataProfile2, my $DataProfile3, my $DataProfile4, my $DataProfile5, my $DataProfile6, my $DataProfile7, my $DataProfile8, my $DataProfile9 };
my $set5GIcon;
my $LTESignalStrengthChange; my $NRSignalStrengthChange;
my $RIL_REQUEST_NETWORK_INFO_FOR_IMS;
my $bandinfo=""; my $bandinfo_flag=0;
my $LGE_FACTORY_VER; my $FINAL_SW_VER;
my $SystemUI_MobileSignalController; my $NW_ICON;
my $mcc;

my $i1; my @NRRSRPt; my @NRRSRPv;
my $i2; my @LTERSRPt; my @LTERSRPv;
my $i3; my @VoiceRATt; my @VoiceRATv; 
my $i4; my @VoiceEARFCNt; my @VoiceEARFCNv;
my $i5; my @DataRATt; my @DataRATv; 
my $i6; my @DataEARFCNt; my @DataEARFCNv;

my $rat = " //1/2/3/9/10/11/15/16:GW, 4/5/6:1x, 7/8/12/13:DO, 14:LTE, 18:IWAN, 19:LTE-CA, 20:NR";
my $nrtype = " //1:FR1(Sub6), 2:FR2(MMW)";
my $rat_mtk = " //8th: 4096:LTE, 8192:LTE_CA, 16384:ENDC, 32768:SA";
my $rat2 = " //1/2/3/8/9/10/15/16:GW, 4/5/6/7:1x, 5/6/12/14:DO, 13:LTE, 18:IWAN, 19:LTE-CA, 20:NR"; #IMS apn

my $currentDir = getcwd();
chdir($currentDir);

#GPS.xml
my $outgps = $currentDir."\\GPS.kml"; unlink $outgps; unless(-e "$outgps"){ open(FPO_GPS, ">$outgps"); }
print FPO_GPS "<?xml version=\"1.0\" encoding=\"UTF-8\"?><kml xmlns=\"http://www.opengis.net/kml/2.2\"><Document><name>GPS.kml</name>\n";

#AdbFilter.txt
my $output = $currentDir."\\AdbFilter.txt"; unlink $output; unless(-e "$output"){ open(FPO, ">$output"); }

my @files =(<*.log*>,<*ssr*>,<*_log_*>); #+ssr_esoc_history.txt
@files = sort {$b cmp $a} @files;
my $line="";

print "Start\n";
foreach my $input (@files){ print "File: $input\n"; ProcessFile($input); } close($output);
print FPO_GPS "</Document></kml>\n"; close($outgps);
if(@LTERSRPt){ plots("LteRSRP.gif", "LTE RSRP", "RSRP [dBm]", 1, -150, -40); } 
if(@NRRSRPt){ plots("NrRSRP.gif", "NR RSRP", "RSRP [dBm]", 2, -150, -40); }
if(@DataRATt){ plots("DataRAT.gif", "DATA RAT", "RAT", 3, 0, 20); }
if(@VoiceEARFCNt){ plots("VoiceLTEBand.gif", "Voice LTE Band", "Band", 4, -1, 86); } #index++, min, max
if(@DataEARFCNt){ plots("DataLTEBand.gif", "Data LTE Band", "Band", 5, -1, 86); } #index++, min, max
if(@VoiceRATt){ plots("VoiceRAT.gif", "VOICE RAT", "RAT", 6, 0, 20); }
print "Finish\n";

sub ProcessFile($)
{
	my ($input) = @_;
	if(not -e $input){ die "Input file $input does not exist\n"; }		
	chomp($input);	
	print FPO "FILE NAME: $input\t==========================================================================================================================================\n";
	open(FPI, "<$input"); 	
	my $tmp;
    while ($line= <FPI>){ chomp($line);     	

		# phone info (PCAS, NTcode, SW version)
		if($line =~ m/pcas_operator|pcas_const_operator|pcas_country| handlePcasInfo:/){ print FPO "$line\n"; } #11-30 22:28:46.104  1346  1360 D mtkfusionrild: [pcas] pcas_operator = TRF, pcas_const_operator = TRF, pcas_country = US for as_id 0
    	if($line =~ m/ntcode=|lge.ntcode_op|NTCode Operator/){ print FPO "$line\n"; } #<6>[    0.000000 / 01-01 00:00:00.000][0] LGE One Binary NTCode Operator : 12 VZW_POSTPAID  //kernel.log #<6>[    0.534408 / 01-01 00:00:00.529][7] 3510 -  bootcmd: lge.ntcode_op=VZW_POSTPAID #<11>[    1.526832 / 01-02 02:18:15.849][6] init: [LGE][SBP] check_single_ca_submit() :  full ntcode : ["1","311,480,FFFFFFFF,FFFFFFFF,FF"] #10-16 11:16:49.432  2809  2809 D LGIMS_SIMOperatorDetector: ImsPolicy: [ PROP: operator=VZW, country=US, sysSimOp=, sysSimOpSub=, model=LM-V450VM, build=user, ntcode="1","311,480,FFFFFFFF,FFFFFFFF,FF", laop=true, maxSlot=1, multi-IMS=false ]  <<<--- main.log
		if($line =~ m/ro.vendor.lge.factoryversion/){ prints($line, "ro.vendor.lge.factoryversion", $LGE_FACTORY_VER, ""); }  #10-12 17:53:46.607   945 30749 I Atd     : ro.vendor.lge.factoryversion is [LMG900AT-00-V10e-LAO-COM-OCT-09-2020-ARB00+0] //system.log
		if($line =~ m/Final Software Version/){ prints($line, "Final Software Version", $FINAL_SW_VER, ""); } #10-12 17:53:46.662   945 30749 I Atd     : [LGE][SBP_VER]Final Software Version : LMG900VMAT-00-V10e-311-480-OCT-09-2020-ARB00+0 //system.log
		
		# radio (modem) state
		if($line =~ m/RADIO_POWER on|RADIO_POWER_OFF|EVENT_RADIO_POWER_OFF_DONE|MODEM_RESET|onReceive: action=android.intent.action.AIRPLANE_MODE/){ print FPO "$line\n"; } #12-02 11:44:42.250  3260  3260 D LGDcTracker: onReceive: action=android.intent.action.AIRPLANE_MODE
		
		# voice and data registration
		if($line =~ m/([0-9]*:[0-9]*:[0-9]*.[0-9]*).*< VOICE_REGISTRATION_STATE.*rat\s+=\s+(\d+)/){ $VoiceRATt[$i3]=$1; $VoiceRATv[$i3]=$2; $i3++;  print FPO "$line\n"; }
		elsif($line =~ m/([0-9]*:[0-9]*:[0-9]*.[0-9]*).*< VOICE_REGISTRATION_STATE.*rat\s+=\s+(\w+)/){ $VoiceRATt[$i3]=$1; $VoiceRATv[$i3]=RAT($2); $i3++;  print FPO "$line\n"; }
		if($line =~ m/([0-9]*:[0-9]*:[0-9]*.[0-9]*).*< VOICE_REGISTRATION_STATE.*earfcn = (\d+)/){ $VoiceEARFCNt[$i4]=$1; $VoiceEARFCNv[$i4]=LTE_EARFCN_to_Band($3); $i4++; }
		if($line =~ m/([0-9]*:[0-9]*:[0-9]*.[0-9]*).*< RIL_REQUEST_LGE_DATA_REGISTRATION_STATE.*.rat\s+=\s+(\d+)/){ $DataRATt[$i5]=$1; $DataRATv[$i5]=$2; $i5++; print FPO "$line\n"; } #ROS before
		elsif($line =~ m/([0-9]*:[0-9]*:[0-9]*.[0-9]*).*< RIL_REQUEST_LGE_DATA_REGISTRATION_STATE.*rat\s+=\s+(\w+)/){ $DataRATt[$i5]=$1; $DataRATv[$i5]=RAT($2); $i5++; print FPO "$line\n"; } #ROS and beyond
		if($line =~ m/([0-9]*:[0-9]*:[0-9]*.[0-9]*).*< RIL_REQUEST_LGE_DATA_REGISTRATION_STATE.*earfcn\s+=\s+(\d+)/){ $DataEARFCNt[$i6]=$1; $DataEARFCNv[$i6]=LTE_EARFCN_to_Band($3); $i6++;  }
		#if($line =~ m/([0-9]*:[0-9]*:[0-9]*.[0-9]*).*onGetNetworkRegistrationStateComplete.*accessNetworkTechnology=LTE.*mEarfcn=(\d+)/){ $DataEARFCNt[$i6]=$1; $DataEARFCNv[$i6]=LTE_EARFCN_to_Band($2); $i6++; } #ROS before

		# protocol related
		if($line =~ m/< OPERATOR/){ prints($line, "OPERATOR", $OPERATOR, ""); }
		if($line =~ m/handleCsNetworkStateChanged|handlePsNetworkStateChanged/){ print FPO "$line\n"; } 
		if($line =~ m/updateLocale: mcc =/){ prints($line, "mcc", $mcc, ""); } #12-07 17:14:38.025  2387  2387 D LocaleTracker: updateLocale: mcc = 310, country = us
		if($line =~ m/Broadcasting ServiceState/){ prints($line, "Broadcasting ServiceState", $Broadcasting_ServiceState, ""); } #09-24 14:23:20.947  3033  3033 D SST     : [0] Broadcasting ServiceState : {mVoiceRegState=1(OUT_OF_SERVICE), mDataRegState=1(OUT_OF_SERVICE), mChannelNumber=-1, duplexMode()=0, mCellBandwidths=[], mVoiceOperatorAlphaLong=Searching for Service, mVoiceOperatorAlphaShort=, mDataOperatorAlphaLong=Searching for Service, mDataOperatorAlphaShort=, isManualNetworkSelection=false(automatic), getRilVoiceRadioTechnology=0(Unknown), getRilDataRadioTechnology=0(Unknown), mCssIndicator=unsupported, mNetworkId=0, mSystemId=0, mCdmaRoamingIndicator=1, mCdmaDefaultRoamingIndicator=-1, mIsEmergencyOnly=false, isUsingCarrierAggregation=false, mLteEarfcnRsrpBoost=0, mNetworkRegistrationInfos=[NetworkRegistrationInfo{ domain=PS transportType=WWAN registrationState=NOT_REG_SEARCHING roamingType=NOT_ROAMING accessNetworkTechnology=UNKNOWN rejectCause=0 emergencyEnabled=false availableServices=[] cellIdentity=null voiceSpecificInfo=null dataSpecificInfo=android.telephony.DataSpecificRegistrationInfo :{ maxDataCalls = 20 isDcNrRestricted = false isNrAvailable = false isEnDcAvailable = false LteVopsSupportInfo :  mVopsSupport = 1 mEmcBearerSupport = 1 mIsUsingCarrierAggregation = false } nrState=NONE rawRegState=2 extraInfos=[-1, -1, -1, -1] endcAvailable=false dcnrRestricted=false 5gAllocated=false}, NetworkRegistrationInfo{ domain=CS transportType=WWAN registrationState=NOT_REG_SEARCHING roamingType=NOT_ROAMING accessNetworkTechnology=UNKNOWN rejectCause=0 emergencyEnabled=false availableServices=[] cellIdentity=null voiceSpecificInfo=VoiceSpecificRegistrationInfo { mCssSupported=false mRoamingIndicator=-1 mSystemIsInPrl=-1 mDefaultRoamingIndicator=-1} dataSpecificInfo=null nrState=NONE rawRegState=2 extraInfos=null endcAvailable=false dcnrRestricted=false 5gAllocated=false}], mNrFrequencyRange=-1, mOperatorAlphaLongRaw=null, mOperatorAlphaShortRaw=null, mIsIwlanPreferred=false mIsVoiceSearching=false mIsDataSearching=false Check64QAM0 Dual carrier0 LTE AdvanceMode0 EnDc=false DcNr Restricted=false 5G Allocated=false phoneId=0}
		if($line =~ m/< RIL_UNSOL_LTE_NETWORK_INFO/){ prints($line, "LTE_NETWORK_INFO", $LTE_NETWORK_INFO, ""); }
		if($line =~ m/set5GIcon\(\) : vzw, nrType/){ prints($line, "nrType", $set5GIcon, $nrtype); } #10-12 18:57:32.261  3569  3913 I LGTelephonyIcons: set5GIcon() : vzw, nrType = 2, isAvailable5G = true, is5GAllocated = true ///main.log
		if($line =~ m/onSetLteNetworkInfo\(\) mLteBand/){ print FPO "$line\n"; } #09-24 14:21:48.937  3033  3033 D SST     : [0] onSetLteNetworkInfo() mLteBand =  66
		if($line =~ m/Handle_EVENT_NETWORK_LOST|data state ::/){ print FPO "$line\n"; } #main.log 	#10-24 14:19:34.736  2180  2180 W LGIMS_J : [ApnInternet$Handle_EVENT_NETWORK_LOST::procMsg:102] data state :: 2 >> 0
		if($line =~ m/< RIL_UNSOL_IMS_PREF_STATUS_IND/){ prints($line, "IMS_PREF_STATUS_IND", $IMS_PREF_STATUS_IND, ""); }
		if($line =~ m/< RIL_REQUEST_NETWORK_INFO_FOR_IMS/){ prints($line, "RIL_REQUEST_NETWORK_INFO_FOR_IMS", $RIL_REQUEST_NETWORK_INFO_FOR_IMS, ""); } #10-21 12:53:00.057  5911  6686 D RILJ    : [2348]< RIL_REQUEST_NETWORK_INFO_FOR_IMS {20, 1, 1, 0, 0, 310, 260, , , 0c1644001, 2c6500, 1, , } [SUB0]
		if($line =~ m/[IMS_AFW] rat/){ print FPO "$line\n"; } #10-21 12:53:00.057  5911  7889 D LGCellInfoTracker: [IMS_AFW] rat : 20, vops : 1, emc_bs : 1, ims_emergency_support : 0, ac_barring_for_emergency : 0, mcc : 310, mnc : 260, plmn1_sib1 : , plmn2_sib1 : , cell_identity : 0c1644001, tac : 2c6500, cell_type : 1, sector_id : , subnet_mask : 
		if($line =~ m/< RIL_REQUEST_GET_CELL_INFO_LIST/){ print FPO "$line\n"; } #10-21 13:09:27.124  5911  6686 D RILJ    : [4679]< RIL_REQUEST_GET_CELL_INFO_LIST [CellInfoNr:{ mRegistered=YES mTimeStamp=2033601477351ns mCellConnectionStatus=1 CellIdentityNr:{ mPci = 150 mTac = 2 mNrArfcn = 126490 mMcc = 310 mMnc = 260 mNci = 1 mAlphaLong = T-Mobile mAlphaShort = T-Mobile } CellSignalStrengthNr:{ csiRsrp = 255 csiRsrq = 255 csiSinr = 255 ssRsrp = 87 ssRsrq = 86 ssSinr = 63 level = 0 } }, CellInfoNr:{ mRegistered=NO mTimeStamp=2033601477351ns mCellConnectionStatus=0 CellIdentityNr:{ mPci = 44 mTac = 2147483647 mNrArfcn = 126490 mMcc = null mMnc = null mNci = 0 mAlphaLong =  mAlphaShort =  } CellSignalStrengthNr:{ csiRsrp = 255 csiRsrq = 255 csiSinr = 255 ssRsrp = 81 ssRsrq = 78 ssSinr = 40 level = 0 } }] [SUB0]
		if($line =~ m/Change in state to:/){ prints($line, "Change in state to:", $SystemUI_MobileSignalController, ""); }  #10-24 14:51:18.482  1688  1858 I [SystemUI]MobileSignalController(4): Change in state to: connected=true,enabled=true,level=5,inetCondition=1,iconGroup=IconGroup(Default),activityIn=true,activityOut=true,rssi=0,lteadvancedmode=0,dataSim=true,networkName=LGE-LTE TestBed|2400 6104,networkNameData=LGE-LTE TestBed|2400 6104,dataConnected=true,roaming=false,isDefault=true,isEmergency=false,airplaneMode=false,carrierNetworkChangeMode=false,userSetup=true,defaultDataOff=falseimsRegistered=false,voiceCapable=false,videoCapable=false,dataActivity=0roaming=false,activity=3,signalZero=false,isSimIcon=false,dataNetType=13,voiceNetType=13,networkIcon=LTE,showRoaming=false,showSearching=false,selectedSim=false,voiceRatType=0,dataRatType=0,cbInfo=null,callState=0,isCat6=false,isMimo=false,isDataEnabled=true,internetConnectStatus=1,oldRoaming=false
		if($line =~ m/networkIcon=(\w+),/){ if($NW_ICON ne $1){ print FPO "//Changed networkIcon=$1\n"; $NW_ICON=$1; print FPO "$line\n"; } } #10-24 14:51:18.482  1688  1858 I [SystemUI]MobileSignalController(4): Change in state to: connected=true,enabled=true,level=5,inetCondition=1,iconGroup=IconGroup(Default),activityIn=true,activityOut=true,rssi=0,lteadvancedmode=0,dataSim=true,networkName=LGE-LTE TestBed|2400 6104,networkNameData=LGE-LTE TestBed|2400 6104,dataConnected=true,roaming=false,isDefault=true,isEmergency=false,airplaneMode=false,carrierNetworkChangeMode=false,userSetup=true,defaultDataOff=falseimsRegistered=false,voiceCapable=false,videoCapable=false,dataActivity=0roaming=false,activity=3,signalZero=false,isSimIcon=false,dataNetType=13,voiceNetType=13,networkIcon=LTE,showRoaming=false,showSearching=false,selectedSim=false,voiceRatType=0,dataRatType=0,cbInfo=null,callState=0,isCat6=false,isMimo=false,isDataEnabled=true,internetConnectStatus=1,oldRoaming=false
		if($line =~ m/SERVICE_STATE serviceState/){ print FPO "$line\n"; } #11-26 20:27:13.957  2348  2348 V KeyguardUpdateMonitor: action android.intent.action.SERVICE_STATE serviceState={mVoiceRegState=2(EMERGENCY_ONLY), mDataRegState=1(OUT_OF_SERVICE), mChannelNumber=64, duplexMode()=0, mCellBandwidths=[2147483647], mOperatorAlphaLong=, mOperatorAlphaShort=, isManualNetworkSelection=false(automatic), getRilVoiceRadioTechnology=16(GSM), getRilDataRadioTechnology=0(Unknown), mCssIndicator=unsupported, mNetworkId=-1, mSystemId=-1, mCdmaRoamingIndicator=-1, mCdmaDefaultRoamingIndicator=-1, mIsEmergencyOnly=true, isUsingCarrierAggregation=false, mLteEarfcnRsrpBoost=0, mNetworkRegistrationInfos=[NetworkRegistrationInfo{ domain=PS transportType=WLAN registrationState=NOT_REG_OR_SEARCHING roamingType=NOT_ROAMING accessNetworkTechnology=IWLAN rejectCause=0 emergencyEnabled=false availableServices=[] cellIdentity=null voiceSpecificInfo=null dataSpecificInfo=null nrState=NONE rRplmn= rawRegState=0 extraInfos=null endcAvailable=false dcnrRestricted=false 5gAllocated=false}, NetworkRegistrationInfo{ domain=CS transportType=WWAN registrationState=NOT_REG_SEARCHING roamingType=NOT_ROAMING accessNetworkTechnology=GSM rejectCause=0 emergencyEnabled=true availableServices=[EMERGENCY] cellIdentity=CellIdentityGsm:{ mLac=6263 mCid=34146 mArfcn=64 mBsic=0x3e mMcc=460 mMnc=00 mAlphaLong=China Mobile mAlphaShort=China Mobile mAdditionalPlmns={}} voiceSpecificInfo=VoiceSpecificRegistrationInfo { mCssSupported=false mRoamingIndicator=-1 mSystemIsInPrl=-1 mDefaultRoamingIndicator=-1} dataSpecificInfo=null nrState=NONE rRplmn=46000 rawRegState=12 extraInfos=null endcAvailable=false dcnrRestricted=false 5gAllocated=false}, NetworkRegistrationInfo{ domain=PS transportType=WWAN registrationState=NOT_REG_OR_SEARCHING roamingType=NOT_ROAMING accessNetworkTechnology=UNKNOWN rejectCause=0 emergencyEnabled=false availableServices=[] cellIdentity=null voiceSpecificInfo=null dataSpecificInfo=android.telephony.DataSpecificRegistrationInfo :{ maxDataCalls = 20 isDcNrRestricted = false isNrAvailable = false isEnDcAvailable = false LteVopsSupportInfo :  mVopsSupport = 1 mEmcBearerSupport = 1 mIsUsingCarrierAggregation = false } nrState=NONE rRplmn= rawRegState=0 extraInfos=[0, 0, 0, 0] endcAvailable=false dcnrRestricted=false 5gAllocated=false}], mNrFrequencyRange=0, mOperatorAlphaLongRaw=, mOperatorAlphaShortRaw=, mIsDataRoamingFromRegistration=false, mIsIwlanPreferred=false mIsVoiceSearching=true mIsDataSearching=false Check64QAM0 Dual carrier0 LTE AdvanceMode0 EnDc=false DcNr Restricted=false 5G Allocated=false phoneId=0} subId=-1
		if($line =~ m/endc_available/){ print FPO "$line\n"; } #12-01 14:42:31.599  1840  1993 E Diag_Lib: qcril_qmi_nas_send_unsol_lge_nrdc_param_change endc_available : 0, restrict_dcnr : 0 
		if($line =~ m/isNrSupported:/){ print FPO "$line\n"; } #12-02 12:07:44.266  3260  3260 I CSST    : isNrSupported:  carrierConfigEnabled: true, AccessFamilySupported: true, isNrNetworkTypeAllowed: true
 		if($line =~ m/UNSOL_RESPONSE_NETWORK_STATE_CHANGED/){ print FPO "$line\n"; }
		if($line =~ m/sendSmCauseBroadcast/){ print FPO "$line\n"; } #12-19 16:30:05.659  2624  2624 D QtiDCT-C: [0]sendSmCauseBroadcast: MLT debug-info=smCause:IP_VERSION_MISMATCH/rilErrorCode:2055/nwType:13/reason:dataEnabled/apnType:ims/apn:ims/retrying:true
		
		# SIM
		if($line =~ m/< GET_SIM_STATUS|CARD_STATE_CHANGED:|CARD_IO_ERROR|The SIM is not inserted|Aka response is failed/){ print FPO "$line\n"; } #12-02 11:56:51.283  3260  3260 D LGUICC  : @@@[IccSwapDialog] CARD_STATE_CHANGED: [slot0] PRESENT -> ABSENT@@@:
		
		# data
		#SEE DataProfile# if($line =~ m/:\s+setDataProfile/){ print FPO "$line\n"; } #data profile 
		if($line =~ m/:\s+DataProfile=(\d+)/){ prints($line, "DataProfile=$1", $DataProfile[$1], ""); } #10-05 20:40:40.019  3141  5334 D RILJ    : DataProfile=0/2/0/VZWINTERNET///0/300/20/0/true/21/0/717703/0/0/true/false [PHONE0]
		if($line =~ m/> SETUP_DATA_CALL|< SETUP_DATA_CALL|setupData:|> DEACTIVATE_DATA_CALL|< DEACTIVATE_DATA_CALL/){ print FPO "$line\n"; }   
		if($line =~ m/Now tear down the data connection|tearDownAll|onDisconnectDone: EVENT_DISCONNECT_DONE|onDisableApn|deactivateDataCall|cleanUpConnectionInternal/){ print FPO "$line\n"; } #<--- MTK #10-21 12:50:20.960  5911  7893 D DC-C-2-Mtk: tearDownAll: reason=releasedByConnectivityService, releaseType=210-21 	#12:50:20.960  5911  7893 D DC-C-2-Mtk: DcActiveState EVENT_DISCONNECT clearing apn contexts, dc={DC-C-2-Mtk: State=MtkDcActiveState mApnSetting=[ApnSettingV7] T-Mobile  IMS, 1904, 310260, ims, null, null, null, null, null, 0, ims, IPV6, IP, true, 0, true, 0, 0, 0, 1440, null, , false, 0, 0, -1, -1, 0 RefCount=1 mCid=601 mCreateTime=-1 mLastastFailTime=-1 mLastFailCause=0 mTag=6 mLinkProperties={InterfaceName: ccmni1 LinkAddresses: [ 2607:fc20:f342:db1:214:22ff:fe01:2345/64 ] DnsAddresses: [ /fd00:976a::9,/fd00:976a::10 ] PcscfAddresses: [ /fd00:976a:14ef:50::5,/fd00:976a:c004:1938::5 ] Domains: null MTU: 1440 TcpBufferSizes: 2097152,4194304,8388608,262144,524288,1048576 Routes: [ ::/0 -> :: ccmni1 ]} networkCapabilities=[ Transports: CELLULAR Capabilities: IMS&NOT_METERED&TRUSTED&NOT_VPN&NOT_ROAMING&NOT_CONGESTED LinkUpBandwidth>=51200Kbps LinkDnBandwidth>=102400Kbps Specifier: <1>] mRestrictedNetworkOverride=false mApnContexts={{mApnType=ims mState=CONNECTED mFallbackCount=0 mWaitingApns={[[ApnSettingV7] T-Mobile  IMS, 1904, 310260, ims, null, null, null, null, null, 0, ims, IPV6, IP, true, 0, true, 0, 0, 0, 1440, null, , false, 0, 0, -1, -1, 0]} mApnSetting={[ApnSettingV7] T-Mobile  IMS, 1904, 310260, ims, null, null, null, null, null, 0, ims, IPV6, IP, true, 0, true, 0, 0, 0, 1440, null, , false, 0, 0, -1, -1, 0} mReason=LOST_CONNECTION mDataEnabled=true mDependencyMet=true}={mTag=6 mApnContext={mApnType=ims mState=CONNECTED mFallbackCount=0 mWaitingApns={[[ApnSettingV7] T-Mobile  IMS, 1904, 310260, ims, null, null, null, null, null, 0, ims, IPV6, IP, true, 0, true, 0, 0, 0, 1440, null, , false, 0, 0, -1, -1, 0]} mApnSetting={[ApnSettingV7] T-Mobile  IMS, 1904, 310260, ims, null, null, null, null, null, 0, ims, IPV6, IP, true, 0, true, 0, 0, 0, 1440, null, , false, 0, 0, -1, -1, 0} mReason=LOST_CONNECTION mDataEnabled=true mDependencyMet=true} mProfileId=2 mRat=20 mOnCompletedMsg={what=0x42000 when=-14m47s438ms obj=Pair{{mApnType=ims mState=CONNECTED mFallbackCount=0 mWaitingApns={[[ApnSettingV7] T-Mobile  IMS, 1904, 310260, ims, null, null, null, null, null, 0, ims, IPV6, IP, true, 0, true, 0, 0, 0, 1440, null, , false, 0, 0, -1, -1, 0]} mApnSetting={[ApnSettingV7] T-Mobile  IMS, 1904, 310260, ims, null, null, null, null, null, 0, ims, IPV6, IP, true, 0, true, 0, 0, 0, 1440, null, , false, 0, 0, -1, -1, 0} mReason=LOST_CONNECTION mDataEnabled=true mDependencyMet=true} 3} target=Handler (com.mediatek.internal.telephony.dataconnection.MtkDcTracker) {63bd6f7} replyTo=null} mRequestType=NORMAL mSubId=1}}}	 #10-21 12:50:20.961  5911  5911 D DCT-C   : onDisableApn: apnType=ims, release type=NORMAL10-21 	#12:50:20.961  5911  5911 D DSM-C   : deactivateDataCall	#10-21 12:54:54.561  5911  7893 D DcNetworkAgent-9: unwanted called. Now tear down the data connection DC-C-2-Mtk		
		if($line =~ m/SocketError/){ print FPO "$line\n"; }  
		if($line =~ m/DataFailCause/){ print FPO "$line\n"; }  
		#if($line =~ m/apnType|tearDown|onDataSetupComplete/){ print FPO "$line\n"; }  
		if($line =~ m/tearDown|onDataSetupComplete/){ print FPO "$line\n"; }  
		
		# radio condition
		if($line =~ m/signalStrengthsChanged LteRSRP\s+=\s+(-?\d+)/){ printp($line, "LteRSRP", "LteSnr", $LTESignalStrengthChange, ""); } #09-24 14:15:54.073  3033  3033 D MapCellularQuality[0]: signalStrengthsChanged LteRSRP = -83, LteSnr = 188, LteRsrq = -130, UmtsRscp = 2147483647, UmtsEcio = 2147483647, GsmRssi = 2147483647, 1xEcio = 2147483647
		if($line =~ m/SignalStrengthChange:\s+{.rsrp\s+=\s+(-?\d+)/){ printp($line, "rsrp", "snr", $NRSignalStrengthChange, " //NR radio condition"); } #09-15 13:37:35.600  2571  3299 D QtiRadioIndication: onSignalStrengthChange: {.rsrp = -73, .snr = 237}
		if($line =~ m/([0-9]*:[0-9]*:[0-9]*.[0-9]*).*signalStrengthsChanged LteRSRP\s+=\s+(-?\d+)/){ if($2<-170||$2>0){$tmp=-150;}else{$tmp=$2;} $LTERSRPt[$i2]=$1; $LTERSRPv[$i2]=$tmp; $i2++; }
		if($line =~ m/([0-9]*:[0-9]*:[0-9]*.[0-9]*).*SignalStrengthChange:\s+{.rsrp\s+=\s+(-?\d+)/){ if($2<-170||$2>0){$tmp=-150;}else{$tmp=$2;} $NRRSRPt[$i1]=$1; $NRRSRPv[$i1]=$tmp; $i1++; }
		#if($line =~ m/STR_RSRP/){ print FPO "$line\n"; } #<--- MTK  #10-21 19:37:12.030  5911  5911 D EchoLocate: DRA: LTE STR_RSRP=-62, STR_RSRQ=-9, STR_SINR=180		#10-21 15:37:18.555  5911  5911 D EchoLocate: DRA: NR STR_RSRP=-44
		#10-21 13:07:00.157  3877  3895 D RmcNwHdlr: [0] updateLgeSignalStrength, gsm_signal_strength: 99, gsm_bit_error_rate: 99, cdma_dbm: 120, cdma_ecio: 0, evdo_dbm: 120, evdo_ecio: 0, evdo_snr: 0, lte_signal_strength: 99, lte_rsrp: 2147483647, lte_rsrq: 2147483647, lte_rssnr: 2147483647, lte_cqi: 2147483647, lte_timing_advance: 2147483647, tdscdma_signal_strength: 99, tdscdma_bit_error_rate: 99, tdscdma_rscp: 2147483647, ssRsrp: 2147483647, ssRsrq: 2147483647, ssSinr: 2147483647, csiRsrp: 2147483647, csiRsrq: 2147483647, csiSinr: 2147483647 rscp_qdbm: -2147483647, ecn0_qdbm: -2147483647,
		if($line =~ m/handleLGESignalStrength/){ print FPO "$line\n"; } #<--- MTK signal strength #10-21 19:37:10.955  3877  3893 D RmcNwHdlr: [0] handleLGESignalStrength, gsm_signal_strength: 99, gsm_bit_error_rate: 99, cdma_dbm: 120, cdma_ecio: 0, evdo_dbm: 120, evdo_ecio: 0, evdo_snr: 0, lte_signal_strength: 30, lte_rsrp: 62, lte_rsrq: 9, lte_rssnr: 180, lte_cqi: 0, lte_timing_advance: 0, tdscdma_signal_strength: 99, tdscdma_bit_error_rate: 99, tdscdma_rscp: 2147483647, ssRsrp: 2147483647, ssRsrq: 2147483647, ssSinr: 2147483647, csiRsrp: 2147483647, csiRsrq: 2147483647, csiSinr: 2147483647 rscp_qdbm: -2147483647, ecn0_qdbm: -2147483647,
		if($line =~ m/GET_CELL_INFO_LIST_NR/){ print FPO "$line\n"; } #<--- MTK signal GET_CELL_INFO_LIST_NR
		
		# protocol
		if($line =~ m/lgeNetBandInfo data i =\s+(\d+)/){ if($1 eq 4){$bandinfo_flag=1;} } #<-- MTK #10-21 13:06:02.286  5911  6686 D RILJ    : lgeNetBandInfo data i = 2 [SUB0]
		#if($line =~ m/lgeNetBandInfo data netBandInfo/){ print FPO "$line\n"; } #<--- MTK
		if($line =~ m/lgeNetBandInfo data netBandInfo =\s+(\d+)/){ $bandinfo="$bandinfo+$1"; if($bandinfo_flag eq 1){ print FPO "Band Info: $bandinfo\n"; $bandinfo=""; $bandinfo_flag=0; } } #<--- MTK #10-21 13:05:24.809  5911  6686 D RILJ    : lgeNetBandInfo data netBandInfo = 66 [SUB0]
		if($line =~ m/RIL_UNSOL_LTE_REJECT_CAUSE/){ print FPO "$line\n"; } #10-05 16:42:15.795  3141  4164 D RILJ    : [UNSL]< RIL_UNSOL_LTE_REJECT_CAUSE 8 [PHONE0]
		if($line =~ m/is not valid|length error /){ print FPO "$line\n"; } #
		
		# crash
		if($line =~ m/modem subsystem failure reason|Assertion failed/){ print FPO "$line\n"; } #<3>[ 1375.453577 / 08-11 14:52:03.800][0] modem subsystem failure reason: lte_symproc_rxfft_taskbuf.c:2357:LTE_SYMPROC_IUSS: Assertion failed (code lte_symproc_vfw_profiling[0]) (arg=0x1eb866,0x1eb866,0x21786e,one more).
		if($line =~ m/serviceDied/){ print FPO "$line\n"; } #09-17 16:08:02.101  3360  4201 D RILJ    : serviceDied [PHONE0] <<<---- RILD died	
		if($line =~ m/_lgedump_esoc_|Failure reason|QC_IMAGE_VERSION_STRING/){ print FPO "$line\n"; } #// ssr_esoc_history.txt #Failure reason : MDM-MPSS:msgr_sio_dsmux.c:740:4G MODEM DOWN, HALTING 5G MODEM. REQUIRE 4G MODE  #QC_IMAGE_VERSION_STRING=MPSS.CE.2.0.c4-00366-SDX50MV2_RMTEFS_PACK-1.309664.1  // ssr_esoc_history.txt
		if($line =~ m/NullPointerException|null object reference/){ print FPO "$line\n"; }
		if($line =~ m/com.android.internal.telephony.CommandException/){ print FPO "$line\n"; }
		if($line =~ m/INTERNAL_ERR|FATAL EXCEPTION|assert/){ print FPO "$line\n"; }
		
		# thermal mitigation
		if($line =~ m/set state=/){ print FPO "$line\n"; } #<6>[   25.766449 / 0120 01-21 11:37:32.992][5] qmi_cooling:qmi_set_cur_or_min_state qmi_set_cur_or_min_state: cdev[modem_mmw2] set state=1

		# call
		if($line =~ m/CallsManager: setCallState/){ print FPO "$line\n"; } #08-12 12:13:13.437  2489  2508 I Telecom : CallsManager: setCallState CONNECTING -> DIALING, call: [TC@1, CONNECTING, tel:911, A, EMC(true), childs(0), has_parent(false), subId(1), [Capabilities: CAPABILITY_MUTE CAPABILITY_CANNOT_DOWNGRADE_VIDEO_TO_AUDIO], [Properties:], ConnTime:0, com.android.phone/com.android.services.telephony.TelephonyConnectionService]: (...->CS.crCo->H.CS.crCo->H.CS.crCo.pICR)->CSW.hCCC@E-E-ALo
		if($line =~ m/< RIL_REQUEST_LGE_GET_CURRENT_CALLS \[id/){ prints($line, "GET_CURRENT_CALLS", $GET_CURRENT_CALLS, ""); } #08-12 12:13:21.680  2670  3430 D RILJ    : [0757]< RIL_REQUEST_LGE_GET_CURRENT_CALLS [id=1,DIALING,toa=129,norm,mo,0,voc,noevp,number=911,cli=1,name=,3,audioQuality=0] [SUB0]
		if($line =~ m/> DIAL /){ print FPO "$line\n"; } 
		#if($line =~ m/DIAL |ANSWER|UNSOL_CALL_RING|EVENT_CALL_RING|Notify new ring|< UNSOL_CDMA_CALL_WAITING|RIL_REQUEST_CDMA_FLASH|HANGUP_FOREGROUND_RESUME_BACKGROUND|UNSOL_CDMA_INFO_REC|UNSOL_VOICE_CODEC_INDICATOR|CdmaConnection/){ print FPO "$line\n"; }   
		if($line =~ m/Dial callType/){ print FPO "$line\n"; } #11-26 20:26:45.356  2850  2850 D TeleService: PreProcessOutgoing: Dial callType : CS
		if($line =~ m/CreateConnectionProcessor: Connection failed/){ print FPO "$line\n"; } #11-26 20:26:45.362  2321  2626 D Telecom : CreateConnectionProcessor: Connection failed: (DisconnectCause [ Code: (RESTRICTED) Label: () Description: (Emergency calls only) Reason: (emergency call failed 37, EMERGENCY_ONLY) Tone: (27) ]): (...->CS.crCo->H.CS.crCo->H.CS.crCo.pICR)->CSW.hCCC(cap/cast)@E-E-AEc
		if($line =~ m/update phone state|Trying.*call|processCallStateChange|callStateLabel|Telecom : Call:/){ print FPO "$line\n"; } 

		# IMS				
		if($line =~ m/LGIMS\s+: REGISTER|LGIMS\s+: SUBSCRIBE|LGIMS\s+: PUBLISH|LGIMS\s+: NOTIFY|LGIMS\s+: INVITE|LGIMS\s+: SIP|LGIMS\s+: PRACK|LGIMS\s+: ACK|LGIMS\s+: BYE|LGIMS\s+: CANCEL|LGIMS\s+: MESSAGE|LGIMS\s+: REFER|LGIMS\s+: UPDATE|LGIMS\s+: INFO|LGIMS\s+: OPTIONS/){ print FPO "$line\n"; } 
		if($line =~ m/CSeq:|: Contact|: Accept-Contact|P-Preferred-Identity:|P-Access-Network-Info:|P-Asserted-Identity/){ print FPO "$line\n"; } #: SIP/2.0|Cseq: #03-04 13:26:45.450 I 3370     LGIMS     P-Asserted-Identity: <sip:voicemail@vzims.com> #08-17 16:00:45.698 3104     4211     LGIMS     SIP/2.0 480 Temporarily not available 
		if($line =~ m/Reason: SIP;cause=|Reason: Q.850;cause=|Reason: USER;text=|Reason: RELEASE_CAUSE|480 Temporarily not available/){ print FPO "$line\n"; } #call end : 01-13 11:02:08.367 I 2636     LGIMS     Reason: SIP;cause=503;text="Session released - service based local policy function aborted session"     #05-19 12:23:17.919 2932     5599     LGIMS     Reason: Q.850;cause=16;text="Normal call clearing"  #03-25 12:29:09.912  4219  5620 I LGIMS   : Reason: USER;text="User Triggered"  #08-17 16:00:45.698 3104     4211     LGIMS     SIP/2.0 480 Temporarily not available             
		if($line =~ m/RTP-RTCP Timeout/){ print FPO "$line\n"; } #01-05 10:09:23.891 2930 	LGIMS	  10:09:23 IMS.SIP.D>> [SIPStack.cpp:7997]			 Reason: USER;text="RTP-RTCP Timeout" # 11-04 15:40:24.683 4338 6488 I LGIMS : ;text="RTP-RTCP Timeout" #14:26:41.909 2280	   LGIMS	 14:26:41 IMS.COM.UC.I>> [GlobalUCMessage.cpp:539] GetByeReason : [607] [RTP;text="RTP-RTCP Timeout"]  
		if($line =~ m/HandleCancel : Reason/){ print FPO "$line\n"; } #09-17 14:58:08.895 1820	 3933	  LGIMS 	14:58:08 IMS.COM.UC.I>> [EarlySession.cpp:2513] HandleCancel : Reason[FAIL_REASON_SESSION_RETRY1X]Code[2] Return[TRUE]	
		if($line =~ m/SendMediaFailedToListn : Reason/){ print FPO "$line\n"; } #MTK HO failure 	#14:26:41.897 2280	 LGIMS	   14:26:41 IMS.COM.UC.I>> [UCMediaMngr.cpp:1660] SendMediaFailedToListn : Reason[FAIL_REASON_MEDIA_NODATA]Code[3]	 
		if($line =~ m/> RIL_REQUEST_SET_IMS_REGISTRATION_STATUS/){ print FPO "$line\n"; } #RILJ    : [1729]> RIL_REQUEST_SET_IMS_REGISTRATION_STATUS regState: 1 regServices: 5 detailState: 2 systemMode: 8 reason: 0 [SUB0]
		if($line =~ m/apn string = IMS, network subtype =/){ prints($line, "network subtype =", $NET_SUB_TYPE, $rat2); } #12-19 07:08:27.190  2956  2956 I LGIMS_J : [ApnIms$Handle_EVENT_NETWORK_CAPABILITIES_CHANGED::procMsg:590] [0] apn string = IMS, network subtype = 13
		
		if($line =~ m/EVENT_HANDOFF_INFORMATION|STATUS_HANDOFF_INIT|STATUS_HANDOFF_/){ print FPO "$line\n"; } #EPSFB
				 
		# VoWiFi HO		
		if($line =~ m/ipcan :/){ print FPO "$line\n"; } #ipcan :|apn string = IMS, network subtype  
		if($line =~ m/Handover request|Handover failed/){ print FPO "$line\n"; } #10-21 12:08:28.406237  2638 21031 D DcActiveStateMachine/DC-C-1-Mtk: DcIwlanActiveState Handover request to CELLULAR		#10-21 12:08:28.526440  2638 21031 D DcActiveStateMachine/DC-C-1-Mtk: onHandoverCompleted: Handover failed with cause=54, start handover retry timer with delay=10000

		# E911
		if($line =~ m/> RIL_REQUEST_SET_VOLTE_E911_SCAN_LIST|< RIL_REQUEST_SET_VOLTE_E911_SCAN_LIST|> RIL_REQUEST_GET_VOLTE_E911_NETWORK_TYPE|< RIL_REQUEST_GET_VOLTE_E911_NETWORK_TYPE/){ print FPO "$line\n"; }  
		if($line =~ m/< RIL_UNSOL_VOLTE_EMERGENCY_CALL_FAIL_CAUSE|RIL_UNSOL_VOLTE_E911_NETWORK_TYPE :|< RIL_UNSOL_VOLTE_EMERGENCY_ATTACH_INFO|< RIL_UNSOL_EMERGENCY_NUMBER_LIST/){ print FPO "$line\n"; }  
		if($line =~ m/< RIL_UNSOL_VOLTE_E911_1x_CONNECTED|< UNSOL_ENTER_EMERGENCY_CALLBACK_MODE|> LAST_CALL_FAIL_CAUSE|< LAST_CALL_FAIL_CAUSE/){ print FPO "$line\n"; }  
		if($line =~ m/> REQUEST_EXIT_EMERGENCY_CALLBACK_MODE|< REQUEST_EXIT_EMERGENCY_CALLBACK_MODE|< UNSOL_EXIT_EMERGENCY_CALLBACK_MODE|> RIL_REQUEST_EXIT_VOLTE_E911_EMERGENCY_MODE|< RIL_REQUEST_EXIT_VOLTE_E911_EMERGENCY_MODE/){ print FPO "$line\n"; }  
		if($line =~ m/GET_NETWORK_TYPE_TIMEOUT|911 over CS|useImsForEmergency/){ print FPO "$line\n"; }  

		# ATC (MTK)
		#TOO MANY# if($line =~ m/AT> AT+|AT< +|AT< OK/){ print FPO "$line\n"; } #<--- MTK AT RIL
		#if($line =~ m/AT> AT\+EAPNACT/){ print FPO "$line\n"; } #<--- MTK AT RIL 
		if($line =~ m/AT< \+ECSQ:\s+(-?\d+),(-?\d+),(-?\d+),(-?\d+),(-?\d+),(-?\d+),(-?\d+),(-?\d+),(-?\d+).*RIL_URC_READER/){ $tmp=$7/4; print FPO "$line \/\/RSRP=$tmp $rat_mtk\n"; } #<--- MTK #10-21 13:03:41.142  3877  3892 I AT      : [0] AT< +ECSQ: 255,255,1,1,1,1,1,4096,32767,-1 (RIL_URC_READER, tid:526226980176) #<--- MTK signal strength, RAT info
		if($line =~ m/AT command timeout/){ print FPO "$line\n"; }  #[0] AT command pending too long, assert!!!on channel 4, tid:2755641792, AT cmd: AT+CGCONTRDP, AT command timeout: 300000ms
		if($line =~ m/AT< \+CEER:/){ print FPO "$line\n"; } 
		if($line =~ m/AT< \+ECSG:/){ print FPO "$line\n"; } 

		# GPS (KML) - http://kml4earth.appspot.com/icons.html
		if($line =~ m/LocationManagerService: incoming location: Location\[gps\s+(-?\d+.\d+),(-?\d+.\d+)/){ print FPO_GPS "<Placemark><Style><Icon><href>http://maps.google.com/mapfiles/kml/pushpin/ylw-pushpin.png</href></Icon></Style> <Point><coordinates>$2,$1,0</coordinates></Point></Placemark>\n"; } #main log #11-25 14:23:01.540  1810  1902 D LocationManagerService: incoming location: Location[gps 32.685350,-96.736552 hAcc=4 et=+4h4m53s616ms alt=87.20111083984375 vel=0.0 vAcc=4 sAcc=0 bAcc=??? {Bundle[{satellites=0, maxCn0=0, meanCn0=0}]}]

		if($line =~ m/java.lang.RuntimeException:/){ print FPO "$line\n"; } 
		if($line =~ m/Ping/){ print FPO "$line\n"; } #07-29 14:07:28.134 14156 16161 I native : (reportStageProgress/StageLatency.cpp:220) Ping 1: 37.48 ms (37.48ms min, 0.00ms jitter)
	}	
	close(FPI);
}

sub prints($) #compare string after $_[1]
{
	my $tmp = (split /$_[1]/, $_[0])[1];
	if($tmp ne $_[2]){ print FPO "$_[0] $_[3]\n"; }
	$_[2] = $tmp;
}

sub printp($) #compare one parameter between $_[1] and $_[2]
{
	my $tmp = (split /$_[2]/, (split /$_[1]/, $_[0])[1])[0];
	if($tmp ne $_[3]){ print FPO "$_[0] $_[4]\n"; }
	$_[3] = $tmp;
}

sub plots($)
{
	#------------------------------------------------------------------------
	# plots( file name, graph name, Y-label, index, Y min value, Y max value) 
	#------------------------------------------------------------------------
	my $file = $currentDir."\\$_[0]";
	my @data = ();
	my $size;

	if($_[3]==1){ @data = (\@LTERSRPt, \@LTERSRPv); $size=scalar @LTERSRPt/30; }
	if($_[3]==2){ @data = (\@NRRSRPt, \@NRRSRPv); $size=scalar @NRRSRPt/30; }
	if($_[3]==3){ @data = (\@DataRATt, \@DataRATv); $size=scalar @DataRATt/30; }
	if($_[3]==4){ @data = (\@VoiceEARFCNt, \@VoiceEARFCNv); $size=scalar @VoiceEARFCNt/30; }
	if($_[3]==5){ @data = (\@DataEARFCNt, \@DataEARFCNv); $size=scalar @DataEARFCNt/30; }
	if($_[3]==6){ @data = (\@VoiceRATt, \@VoiceRATv); $size=scalar @VoiceRATt/30; }
	
	print "Found $_[1]\n";
	my $graph = GD::Graph::lines->new(1200,500);
	$graph->set( 
	title       	  => "$_[1]",   
	#x_label     	  => 'Time', 
	y_label			  => "$_[2]", 
	transparent       => '0',
	bgclr             => 'white',
	boxclr            => 'white',
	fgclr             => 'white',
	labelclr          => 'black',
	axislabelclr      => 'black',
	legendclr         => 'black', 
	valuesclr         => 'black', 
	textclr           => 'black', 
	dclrs     		  => [ ('red') ],
	box_axis          => 0,
	line_width        => 3,
	y_number_format   => '%.1d',
	x_labels_vertical => 1,
	x_tick_offset     => 1,
	x_label_skip      => $size,
	t_margin          => 10,
	b_margin          => 10,
	l_margin          => 10,
	r_margin          => 15,  
	y_min_value       => $_[4],
	y_max_value       => $_[5],
	y_tick_number     => 8,
	); 
	$graph->set_title_font(GD::Font->Large);
	$graph->set_legend_font(GD::Font->Large);
	$graph->set_x_label_font(GD::Font->Large);
	$graph->set_y_label_font(GD::Font->Large);
	$graph->set_x_axis_font(GD::Font->Large);
	$graph->set_y_axis_font(GD::Font->Large);
	my $gd = $graph->plot(\@data) or die $graph->error; 
	open(IMG, ">","$file") or die $!;
	binmode IMG;
	print IMG $gd->gif;
	close IMG;
}

sub RAT($)
{
	my $tmp = $_[0];
	if($tmp eq "UNKNOWN"){ return 0; }
    elsif($tmp eq "GPRS"){ return 1; }
    elsif($tmp eq "EDGE"){ return 2; }
    elsif($tmp eq "UMTS"){ return 3; }
    elsif($tmp eq "IS95A"){ return 4; }
    elsif($tmp eq "IS95B"){ return 5; }
    elsif($tmp eq "ONE_X_RTT"){ return 6; }
    elsif($tmp eq "EVDO_0"){ return 7; }
    elsif($tmp eq "EVDO_A"){ return 8; }
    elsif($tmp eq "HSDPA"){ return 9; }
    elsif($tmp eq "HSUPA"){ return 10; }
    elsif($tmp eq "HSPA"){ return 11; }
    elsif($tmp eq "EVDO_B"){ return 12; }
    elsif($tmp eq "EHRPD"){ return 13; }
    elsif($tmp eq "LTE"){ return 14; }
    elsif($tmp eq "HSPAP"){ return 15; }
    elsif($tmp eq "GSM"){ return 16; }
    elsif($tmp eq "TD_SCDMA"){ return 17; }
    elsif($tmp eq "IWLAN"){ return 18; }
    elsif($tmp eq "LTE_CA"){ return 19; }
    elsif($tmp eq "NR"){ return 20; }
    else{ return 0; }
}

sub LTE_EARFCN_to_Band ($)
{
	my $tmp = $_[0];
	if($tmp <= 599){			return 1; } 
	elsif($tmp <= 1199){		return 2; }
	elsif($tmp <= 1949){		return 3; }
	elsif($tmp <= 2399){		return 4; }
	elsif($tmp <= 2649){		return 5; }
	elsif($tmp <= 2749){		return 6; }
	elsif($tmp <= 3449){		return 7; }
	elsif($tmp <= 3799){		return 8; }
	elsif($tmp <= 4149){		return 9; }
	elsif($tmp <= 4749){		return 10; }
	elsif($tmp <= 4949){		return 11; }
	elsif($tmp <= 5179){ 	return 12; }
	elsif($tmp <= 5279){		return 13; }
	elsif($tmp <= 5379){		return 14; }
	elsif($tmp <= 5849){		return 17; }
	elsif($tmp <= 5999){		return 18; }
	elsif($tmp <= 6149){		return 19; }
	elsif($tmp <= 6449){		return 20; }
	elsif($tmp <= 6599){		return 21; }
	elsif($tmp <= 7399){		return 22; }
	elsif($tmp <= 7699){ 	return 23; }
	elsif($tmp <= 8039){ 	return 24; }
	elsif($tmp <= 8689){ 	return 25; }
	elsif($tmp <= 9039){ 	return 26; }
	elsif($tmp <= 9209){ 	return 27; }
	elsif($tmp <= 9659){ 	return 28; }
	elsif($tmp <= 9769){ 	return 29; }
	elsif($tmp <= 9869){ 	return 30; }
	elsif($tmp <= 9919){ 	return 31; }
	elsif($tmp <= 10359){ 	return 32; }
	elsif($tmp >= 36000 && $tmp <= 36199){		return 33; } 
	elsif($tmp <= 36349){ 	return 34; }
	elsif($tmp <= 36949){ 	return 35; }
	elsif($tmp <= 37549){ 	return 36; }
	elsif($tmp <= 37749){ 	return 37; }
	elsif($tmp <= 38249){ 	return 38; }
	elsif($tmp <= 38649){ 	return 39; }
	elsif($tmp <= 39649){ 	return 40; }
	elsif($tmp <= 41589){ 	return 41; }
	elsif($tmp <= 43589){ 	return 42; }
	elsif($tmp <= 45589){ 	return 43; }
	elsif($tmp <= 46589){ 	return 44; }
	elsif($tmp <= 46789){ 	return 45; }
	elsif($tmp <= 54539){ 	return 46; }
	elsif($tmp <= 55239){	return 47; }
	elsif($tmp <= 56739){ 	return 48; }
	elsif($tmp <= 58239){	return 49; }
	elsif($tmp <= 59089){ 	return 50; }
	elsif($tmp <= 59139){ 	return 51; }
	elsif($tmp <= 60139){ 	return 52; }
	elsif($tmp >= 65536 && $tmp <= 66435){	return 65; } 
	elsif($tmp <= 67335){ 	return 66; }
	elsif($tmp <= 67535){ 	return 67; }
	elsif($tmp <= 67835){ 	return 68; }
	elsif($tmp <= 68335){ 	return 69; }
	elsif($tmp <= 68585){ 	return 70; }
	elsif($tmp <= 68935){ 	return 71; }
	elsif($tmp <= 68985){ 	return 72; }
	elsif($tmp <= 69035){	return 73; }
	elsif($tmp <= 69465){ 	return 74; }
	elsif($tmp <= 70315){	return 75; }
	elsif($tmp <= 70365){	return 76; }
	elsif($tmp <= 70545){ 	return 85; }
	else{ 						return -1; } 
}


__END__

typedef enum {
    RADIO_TECH_UNKNOWN = 0,
    RADIO_TECH_GPRS = 1,
    RADIO_TECH_EDGE = 2,
    RADIO_TECH_UMTS = 3,
    RADIO_TECH_IS95A = 4,
    RADIO_TECH_IS95B = 5,
    RADIO_TECH_1xRTT =  6,
    RADIO_TECH_EVDO_0 = 7,
    RADIO_TECH_EVDO_A = 8,
    RADIO_TECH_HSDPA = 9,
    RADIO_TECH_HSUPA = 10,
    RADIO_TECH_HSPA = 11,
    RADIO_TECH_EVDO_B = 12,
    RADIO_TECH_EHRPD = 13,
    RADIO_TECH_LTE = 14,
    RADIO_TECH_HSPAP = 15, // HSPA+
    RADIO_TECH_GSM = 16, // Only supports voice
    RADIO_TECH_TD_SCDMA = 17,
    RADIO_TECH_IWLAN = 18,
    RADIO_TECH_LTE_CA = 19
} RIL_RadioTechnology;

=ROS and beyond=
enum class RadioTechnology : int32_t {
    UNKNOWN = 0,
    GPRS = 1,
    EDGE = 2,
    UMTS = 3,
    IS95A = 4,
    IS95B = 5,
    ONE_X_RTT = 6,
    EVDO_0 = 7,
    EVDO_A = 8,
    HSDPA = 9,
    HSUPA = 10,
    HSPA = 11,
    EVDO_B = 12,
    EHRPD = 13,
    LTE = 14,
    HSPAP = 15,
    GSM = 16,
    TD_SCDMA = 17,
    IWLAN = 18,
    LTE_CA = 19,
    /**
     * 5G NR. This is only use in 5G Standalone mode.
     */
    NR = 20,
};
