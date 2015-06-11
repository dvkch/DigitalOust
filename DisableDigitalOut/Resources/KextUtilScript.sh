#!/bin/sh
#set -x
#
#Set env variable LANG=ru_RU.UTF-8 for correct display cyrillic file names
#export LANG=ru_RU.UTF-8

#echo "\${1}=${1}"
#echo "\${2}=${2}"
#echo "\${3}=${3}"
#echo "\${4}=${4}"

WorkDir1="/System/Library/Extensions"
WorkDir2="/Library/Extensions"
WorkDir3="/Extra/Extensions"

LeoCacheFile="/System/Library/Extensions.mkext"
SnowLeoCacheFile="/System/Library/Caches/com.apple.kext.caches/Startup/Extensions.mkext"
CacheFile="/System/Library/Caches/com.apple.kext.caches/Startup/kernelcache"
AppleKextExcludeListKextInfoPlistPath=`find /System/Library/Extensions/AppleKextExcludeList.kext -name Info.plist`
BootPlistPath="/Library/Preferences/SystemConfiguration/com.apple.Boot.plist"
SystemCacheFile=""
SystemName=""

kext_msdosfs=1
kext_AppleKextExcludeList=1
key_v=0
key_kext_dev_mode_1=1

KernOSRelease=`sysctl -n kern.osrelease | cut -d "." -f1`

HomeDir=~
TimeOut=10 # timeout (default 60 sec) of the repair operation

### Release-Type Variables ###

#PROGRAM=$(basename "$1")
Version="2.6.1"
Creator="cVad"
Released="2008-2014"

memoMSG() {

# Programm attributes
cat << EOF
                                 -- Kext Utility --
                              v$Version © $Creator $Released
                                 Mac OS X 10.5-10.10
                       Super Fast Repair all Kexts permissions
                           OSKextSigExceptionList Updater
                               /S/L/E Kexts Installer
                                Mkext Packer/UnPacker
                                 cvad-mac.narod.ru
                                  www.applelife.ru

EOF
}

SystemSpecMSG() {
#set +x
#Block show system specifications
KERN_Version=`echo $(sysctl -n kern.version | cut -d ";" -f1)`
MachineHardwareName=`uname -m`

MODEL_ID=`sysctl -n hw.model`

ProductName=`sw_vers |grep ProductName`
ProductVersion=`echo $(sw_vers |grep ProductVersion)`
BuildVersion=`echo $(sw_vers |grep BuildVersion)`

User=$USER
KERN_Hostname=`sysctl -n kern.hostname`
KERN_Bootargs=`sysctl -n kern.bootargs`

CPU_TYPE="`sysctl -n machdep.cpu.brand_string | sed 's/  */ /g'`"
CPU_FEATURES="`sysctl -n machdep.cpu.features` `sysctl -n machdep.cpu.extfeatures` `sysctl -n machdep.cpu.leaf7_features`"
CPUCores="`sysctl -n hw.physicalcpu`"
CPUThreads="`sysctl -n hw.logicalcpu`"
temp="`sysctl -n hw.cpufrequency_max`"
if [ ${temp} ]
	then
		CPUFrequency_MAX=$((${temp}/1000000))
	else
		CPUFrequency_MAX=0
fi
temp="`sysctl -n hw.cpufrequency_min`"
if [ ${temp} ]
	then
		CPUFrequency_MIN=$((${temp}/1000000))
	else
		CPUFrequency_MIN=0
fi
temp="`sysctl -n hw.cpufrequency`"
if [ ${temp} ]
	then
		CPUFrequency=$((${temp}/1000000))
	else
		CPUFrequency=0
fi
temp="`sysctl -n hw.busfrequency`"
if [ ${temp} ]
	then
		BUSFrequencyFSB=$((${temp}/1000000))
		BUSFrequency=$(($BUSFrequencyFSB/4))
	else
		BUSFrequencyFSB=0
		BUSFrequency=0
fi
temp="`sysctl -n hw.l1icachesize`"
if [ ${temp} ]
	then
		Cache_L1i=$((${temp}/1024))
	else
		Cache_L1i=0
fi
temp="`sysctl -n hw.l1dcachesize`"
if [ ${temp} ]
	then
		Cache_L1d=$((${temp}/1024))
	else
		Cache_L1d=0
fi
temp="`sysctl -n hw.l2cachesize`"
if [ ${temp} ]
	then
		Cache_L2=$((${temp}/1024))
	else
		Cache_L2=0
fi
temp="`sysctl -n hw.l3cachesize`"
if [ ${temp} ]
	then
		Cache_L3=$((${temp}/1024))
	else
		Cache_L3=0
fi
CPUSignature="`sysctl -n machdep.cpu.signature`"
CPUSignatureHex=$(echo "obase=16; $CPUSignature" | bc)

temp="`sysctl -n hw.memsize`"
if [ ${temp} ]
	then
		MEMSIZE=$((${temp}/1048576))
	else
		MEMSIZE=0
fi
SwapUsage="`sysctl -n vm.swapusage`"
HibernateMode="`sysctl -n kern.hibernatemode`"

#Bootargs     : ${KERN_Bootargs} # script not work in 10.8 with non utf8 args

cat << EOF
ProductName  : Mac OS X $ProductVersion $BuildVersion
Bootargs     : $KERN_Bootargs
Kernel       : $KERN_Version
Model ID     : $MODEL_ID KernelMode: $MachineHardwareName
CPU TYPE     : ${CPU_TYPE}
CPU ID       : Ox$CPUSignatureHex ($CPUSignature) 
Cores        : ${CPUCores} Cores, ${CPUThreads} Threads @ ${CPUFrequency_MAX}MHz Bus: ${BUSFrequency}MHz FSB: ${BUSFrequencyFSB}MHz
Caches       : L1i:${Cache_L1i}Kb L1d:${Cache_L1d}Kb L2:${Cache_L2}Kb L3:${Cache_L3}Kb
CPU Features : ${CPU_FEATURES}
RAM          : ${MEMSIZE}Mb HibernateMode: $HibernateMode
SwapUsage    : $SwapUsage
User         : $USER on $KERN_Hostname

EOF
}

StartMSG() {

#       Leopard        -  9,
#       Snow  Leopard  - 10,
#       Lion           - 11
#       Mountain Lion  - 12
#       Mavericks      - 13
#       Yosemite       - 14

case "${KernOSRelease}" in
    [0-8])
		echo "Detected ... unsupported MAC OS X system."
                SystemName="unsupported MAC OS X system"
        ;;
    9)
		echo "Detected  ...  MAC OS X \"Leopard\"."
                SystemCacheFile="${LeoCacheFile}"
                SystemName="MAC OS X \"Leopard\""
        ;;
    10)
		echo "Detected  ...  MAC OS X \"Snow Leopard\"."
                SystemCacheFile="${SnowLeoCacheFile}"
                SystemName="MAC OS X \"Snow Leopard\""
        ;;
    11)
		echo "Detected  ...  MAC OS X \"Lion\"."
                SystemCacheFile="${CacheFile}"
                SystemName="MAC OS X \"Lion\""
        ;;
    12)
		echo "Detected  ...  MAC OS X \"Mountain Lion\"."
                SystemCacheFile="${CacheFile}"
                SystemName="MAC OS X \"Mountain Lion\""
        ;;
    13)
		echo "Detected  ...  MAC OS X \"Mavericks\"."
                SystemCacheFile="${CacheFile}"
                SystemName="MAC OS X \"Mavericks\""
        ;;
    14)
		echo "Detected  ...  MAC OS X \"Yosemite\"."
                SystemCacheFile="${CacheFile}"
                SystemName="MAC OS X \"Yosemite\""
        ;;
	*)
		echo "Detected  ...  $(sysctl -n kern.version | cut -d ":" -f1)."
                SystemCacheFile="${CacheFile}"
                SystemName=`echo $(sysctl -n kern.version | cut -d ":" -f1)`
        ;;
esac

echo
echo "Start working: $(date "+%Y-%m-%d %H:%M:%S %z")"
echo

}

ErrMSG() {	

	memoMSG
	usage
}

usage() {
	# Usage format
cat <<EOF
     Usage: 

     1. To install the drivers Drop all the driver files with valid extension
     	(*.kext, *.plugin, *.bundle, *.ppp) on the app icon.
        It will be installed to "/System/Library/Extensions/" folder.
     2. To Repair the kext permissions for all system folders, just
     	run the app.
     3. To Repair&Pack a folder with kext files in the mkext cache file,
        drop this folder on the app icon.
       "Extensions.mkext" file will be placed near "Extensions" folder.
     4. To UnPack the mkext cache file, drop the mkext file on the app icon.
        Folder with your extracted files will be placed on the Desktop.

                                                                    Enjoy ...
    
EOF
}

CheckConfig() {
if [[ -e ./KU_config.plist ]] # Check if PatchKext InfoPlist exist
	then
		local key_value="$(/usr/libexec/PlistBuddy -c "Print PatchKexts:msdosfs.kext" "./KU_config.plist" 2>/dev/null)"
		if [[ "${key_value}" = "false" ]]
			then
				kext_msdosfs=0
				#echo "kext_msdosfs=false"
		fi
		key_value="$(/usr/libexec/PlistBuddy -c "Print PatchKexts:AppleKextExcludeList.kext" "./KU_config.plist" 2>/dev/null)"
		if [[ "${key_value}" = "false" ]]
			then
				kext_AppleKextExcludeList=0
				#echo "kext_AppleKextExcludeList=false"
		fi
		key_value="$(/usr/libexec/PlistBuddy -c "Print AddBootArgs:-v" "./KU_config.plist" 2>/dev/null)"
		if [[ "${key_value}" = "true" ]]
			then
				key_v=1
				#echo "key_v=false"
		fi
		key_value="$(/usr/libexec/PlistBuddy -c "Print AddBootArgs:kext-dev-mode=1" "./KU_config.plist" 2>/dev/null)"
		if [[ "${key_value}" = "false" ]]
			then
				key_kext_dev_mode_1=0
				#echo "key_kext_dev_mode_1=false"
		fi
fi
}

SetPermissionsMod()
{ 
#set +x
# Standart commands:
# sudo chown -R root:wheel /System/Library/Extensions/Some.kext
# sudo chmod -R 755 /System/Library/Extensions/Some.kext
	CountFiles=0
	CountKext=0
	#CountPpp=0
	#CountPlugin=0
	#CountBundle=0
	#CountPlist=0
	#CountBin=0
	AllCodeFiles=0

InDir=$1
printf "Repairing Permissions for \"${InDir}\" ..."

OldIFS=$IFS   # save old $IFS
IFS=$'\n'     # new $IFS  

starttime=`date +%s`

    for files in $(find "${InDir}")
	    do
	        case "${files}" in
				*.kext|*.ppp|*.plugin|*.bundle)  let "CountKext+=1";  chmod 755 "${files}";;
				*CodeDirectory|*CodeRequirements|*CodeResources|*CodeSignature|*.plist|*.strings|*PkgInfo|*.dfu|*.zlib|*.pdf|*LICENSE|*.icns|*.tif|*.tiff)
				if [[ -f "${files}" ]] 
#   				If files (not link) chmod 644
					then 
						chmod 644 "${files}"
#   				If files is link chmod -h 755
                    else
						chmod -h 755 "${files}"
				fi
				let "AllCodeFiles+=1"
				;;

				*)
		        chmod -h 755 "${files}" ;;

			esac

			chown -h root:wheel "${files}"

	        let "CountFiles+=1"
	
            if [ $((CountFiles/400*400)) -eq ${CountFiles} ] # count very quickly
				then
					 printf "."
			fi

    	done

finishtime=`date +%s`

IFS=$OldIFS   # return old $IFS

printf " Done.\n"

# echo
#echo "-- Total processed: ${CountFiles} files (${CountKext} kexts) for $(($finishtime-$starttime)) sec."
echo "-- Total processed: ${CountFiles} files for $(($finishtime-$starttime)) sec."

echo

}

SystemCacheUpdate() {

#echo "SystemCacheUpdate() - ${SystemCacheFile}"
#echo "SystemCacheUpdate() Detected  ...  ${SystemName}"

let "count=0"
#echo "count=${count}"
#echo "TimeOut=${TimeOut}"

printf "Updating the system cache files ."
        
rm -Rf /System/Library/Caches/com.apple.bootstamps/* 2>/dev/null
rm -Rf /System/Library/Caches/com.apple.kernelcaches/* 2>/dev/null
rm -Rf /System/Library/Caches/com.apple.kext.caches/Directories/Library/Extensions/* 2>/dev/null
rm -Rf /System/Library/Caches/com.apple.kext.caches/Directories/System/Library/Extensions/* 2>/dev/null
rm -Rf /System/Library/Caches/com.apple.kext.caches/Startup/* 2>/dev/null
rm -Rf /System/Library/Extensions/Caches/* 2>/dev/null
rm -f "${SystemCacheFile}" 2>/dev/null
        
# for LION
#touch "${WorkDir1}"
#killall -HUP kextd&
#kextcache -system-caches&
#kextcache -update-volume / -force&
#echo "WorkDir1 - ${WorkDir1}"
#echo "WorkDir2 - ${WorkDir2}"

touch "${WorkDir1}"
touch "${WorkDir2}"
#killall -HUP kextd&

# kextcache creates several kinds of kext caches.  The first is the prelinked kernel (also known as a ``kernelcache''),
# which contains the kernel code and the essential files (info dictionary and executable) for an arbitrary set of kexts,
# with kext executables linked for their run-time locations. A prelinked kernel speeds early system startup by collecting
# these many files in one place for the booter to locate, and by having each kext linked in place and ready to start as
# needed.  To create or update a prelinked kernel, use the -prelinked-kernel or -system-prelinked-kernel option.

# Other kext caches collect specific data from the info dictionaries of kexts. There are many individual caches for
# specific subsets of data; they care collectively called system info caches. These caches are used to optimize disk I/O
# when working with kexts during late system startup and beyond. To update the system kext info caches for the root volume,
# use the -system-caches option

# The last type of kext cache is the mkext cache, which contains the essential files (info dictionary and executable) for
# an arbitrary set of kexts; executables are unrelocated. Mkext is a legacy format that was used on prior releases of
# Mac OS X. To create an mkext cache, use one of the -mkext, -mkext1, or -mkext2 options, with appropriate filtering
# options, described below.

# -l, -local-root
# Specifies that for directory arguments, only extensions required for local disk boot be included in a cache.
# Kexts explicitly indicated by name or identifier are included unconditionally; to apply this filter to all kexts,
# use the -local-root-all option. -L, -local-root-all
# Specifies that only extensions required for local disk boot be included in a cache, regardless of whether they are
# from a repository directory or are explicitly indicated by name or identifier.  To apply this restriction only to kexts
# from repository directories, use the -local-root option.

kextcache -system-caches -local-root-all& # for making 32&64bit info dictionaries kext caches
#kextcache -update-volume / -force&

# -e, -system-mkext
# This option is provided for legacy compatibility, and is simply an alias to -system-prelinked-kernel.
         
#kextcache -system-mkext -local-root&

#kextcache -system-prelinked-kernel&

while sleep 1
	do
		if [ -f "${SystemCacheFile}" ]
			then
				printf " Done\n"
				#if [ $count -gt $TimeOut ]
				#then
					#echo "-- Build time = $((count-TimeOut)) sec"
				#else
					echo "-- Build time = $count sec"
				#fi
				return
		elif [ $count -eq $TimeOut ]
			then
				#printf " False\n"
				#echo "-- Timeout $count sec"
				#echo
				#printf "Forced updating the system cache files "
				#touch "${WorkDir1}"
				kextcache -update-volume / -force&
		elif [ $count -gt $((12*TimeOut-1)) ]  # timeout2=12*timeout=12*10=120sec
			then
				printf " False\n"
				echo "-- Timeout ${count} sec.\n"
				echo "-- Unknown error --"
				return
		fi
		let "count+=1"

		if [ `expr "$count" % 2` -eq "0" ]
			then
				printf "."
		fi


	done
}

packMkext() {

	
	FullDropInDir=$1
	DirDropInDir=$(dirname "${FullDropInDir}") 
	BaseDropInDir=$(basename "${FullDropInDir}") 
	
if [[ `find "${FullDropInDir}" -name *.kext` ]]

    then
cat <<EOF
Task: Pack "${FullDropInDir}"
        to "${DirDropInDir}/Extensions.mkext"
EOF
		
    	echo
    	
        SetPermissionsMod "${FullDropInDir}"

        if [ -e "$DirDropInDir/Extensions.mkext" ]
            then
                printf "BackUp \"Extensions.mkext\" to \"Extensions.bak.mkext\" ... "
                mv -f "$DirDropInDir/Extensions.mkext" "$DirDropInDir/Extensions.bak.mkext"
                printf "Done.\n"
                echo
        fi
	
    	touch "$FullDropInDir"
    	
    	starttime=`date +%s`

    	i386_ppc_kexts=$( kextfind -- "${FullDropInDir}" \( -arch-exact i386 -or -arch-exact ppc,i386 \) )""
        
		if [[ "${SnowLeoExist}" = "no" || ! "" = "${i386_ppc_kexts}" ]]

#			If one of the conditions is true then	
			then
					printf "Found i386 (arch) only kext(s).\n"
					printf "Packing i386 (arch) \"Extensions.mkext\" ... "
	    			
	    			if ( kextcache -a i386 -z -m "$DirDropInDir/Extensions.mkext" "$FullDropInDir" ) 
	    				then
	    					printf "Done.\n"
	    					finishtime=`date +%s`
		   	 				echo "-- Build time = $(($finishtime-$starttime)) sec."
	    					echo
	    					printf "Repair \"Extensions.mkext\" permission ... "
	    			
	    					chmod -R 644 "$DirDropInDir/Extensions.mkext"
	    					chown -R root:wheel "$DirDropInDir/Extensions.mkext"
	    			
		    				printf "Done.\n"
	    					echo
	    				else 
	    					echo
	    					echo "Sorry, could not create \"Extensions.mkext\""
	    					echo
	    					return
	
	    			fi
			else
#					printf "Found i386/x86_64 (arch) kext(s).\n"
					printf "Packing i386/x86_64 (arch) \"Extensions.mkext\" ... "

#                   /usr/sbin/kextcache -z -m /Extra/Extensions.mkext /Extra/Extensions/					
	    			if ( kextcache -z -m "$DirDropInDir/Extensions.mkext" "$FullDropInDir" ) 
	    				then
	    					printf "Done.\n"
	    					finishtime=`date +%s`
		   	 				echo "-- Build time = $(($finishtime-$starttime)) sec."
	    					echo
	    					printf "Repair \"Extensions.mkext\" permission ... "
	    			
	    					chmod -R 644 "$DirDropInDir/Extensions.mkext"
	    					chown -R root:wheel "$DirDropInDir/Extensions.mkext"
	    			
		    				printf "Done.\n"
	    					echo
	    				else 
	    					echo
	    					echo "Sorry, could not create \"Extensions.mkext\""
	    					echo
	    					return
	    			fi
		fi
	else
		printf "Nothing to do -- Kext files not found.\n"
		printf "\n"
fi
} 

unpackMkext()	{

cat <<EOF
Task: UnPack "${FullDropName}"
          to "${HomeDir}/Desktop/${BaseDropName}_content"
EOF
	echo

	printf "Search \"${BaseDropName}_content\" ... "

	if [ -d "${HomeDir}/Desktop/${BaseDropName}_content" ]
		then
			printf "Found.\n"
			rm -rf "${HomeDir}/Desktop/${BaseDropName}_content.bak"
			echo
			printf "BackUp \"${BaseDropName}_content\" to \"${BaseDropName}_content.bak\" ... "
			mv -f "${HomeDir}/Desktop/${BaseDropName}_content/" "${HomeDir}/Desktop/${BaseDropName}_content.bak/" 
			printf "Done.\n"
			mkdir -p -m 775 "${HomeDir}/Desktop/${BaseDropName}_content"
			echo
		else
			printf "Not Found.\n"
			echo
			mkdir -p -m 775 "${HomeDir}/Desktop/${BaseDropName}_content"
	fi
			printf "UnPacking \"${BaseDropName}\" ... "

	mkextunpack -v -d "${HomeDir}/Desktop/${BaseDropName}_content" "$FullDropName" 2> /dev/null
	printf "Done.\n"
	echo

}

AddBootArg() {

local val=`/usr/libexec/PlistBuddy -c "Print :\"Kernel Flags\"" "${BootPlistPath}"`

if ! [[ `echo "${val}" | grep -e "${1}"` ]]
	then
		if [[ ${val} ]]
			then
				#echo "Found Boot Args: ${val}"
				val="${val}"" ${1}"
			else
				val="${1}"
		fi
		if [[ ! `/usr/libexec/PlistBuddy -c "Set :\"Kernel Flags\" \"${val}\"" "${BootPlistPath}"` ]]
			then
				echo "Add Boot arg: ${1} in com.apple.Boot.plist" 
				echo
		fi
 	else
		echo "Boot arg: ${1} already exist in com.apple.Boot.plist"
		echo
fi
}

UpdateOSKextSigExceptionList() {

KextsTestDir="${1}"
#echo "1=${1}"
#echo "KextsTestDir=${KextsTestDir}"

# cat <<EOF
# Task:	Update OSKextSigExceptionList.
#  
# EOF

if [[ ! "${AppleKextExcludeListKextInfoPlistPath}" ]] # Check if AppleKextExcludeList.kext exist
	then
		echo "AppleKextExcludeList.kext not found"
		return
fi

AppleKextExcludeListKextCFBundleVersion="$(/usr/libexec/PlistBuddy -c "Print CFBundleVersion" "${AppleKextExcludeListKextInfoPlistPath}" 2>/dev/null)"
echo "Found $(/usr/libexec/PlistBuddy -c "Print CFBundleIdentifier" "${AppleKextExcludeListKextInfoPlistPath}" 2>/dev/null):$AppleKextExcludeListKextCFBundleVersion"
if [[ ! -e "${AppleKextExcludeListKextInfoPlistPath/Info.plist/Info_$AppleKextExcludeListKextCFBundleVersion.plist}" ]]
	then
		BackUpInfoPlist="${AppleKextExcludeListKextInfoPlistPath/Info.plist/Info_$AppleKextExcludeListKextCFBundleVersion.plist}"
		cp "${AppleKextExcludeListKextInfoPlistPath}" "${BackUpInfoPlist}"
		# echo ${A#*AB}
		echo "Backup ${AppleKextExcludeListKextInfoPlistPath#*Contents/} to ${BackUpInfoPlist#*Contents/}"
		
fi
echo

printf "Updating OSKextSigExceptionList ."

starttime=`date +%s`

AllCheckKextsCount=0
AddedUnSigKextsCount=0
UpdatedUnSigKextsCount=0
ErrorsCount=0


KextsInfoPlistPath=`find "${KextsTestDir}" -name Info.plist`
#echo "${KextsInfoPlistPath}"

# KextArch=$(kextfind "${CurrentKext}" -report -no-header -pid)
# 
OldIFS=$IFS   # save old $IFS
IFS=$'\n'     # new $IFS  
# 
#echo "Examine AppleKextExcludeList.kext for entry:"
for CurrentKextInfoPlistPath in ${KextsInfoPlistPath}
	do
	# Found Info for Current Kext 
	CurrentKextCFBundleIdentifier="$(/usr/libexec/PlistBuddy -c "Print CFBundleIdentifier" "${CurrentKextInfoPlistPath}" 2>/dev/null)"
 	if [[ ! "${CurrentKextCFBundleIdentifier}" ]]
  		then
  			#echo "Not Found CFBundleIdentifier in: \"${CurrentKextInfoPlistPath}\""
  			let "ErrorsCount+=1"
  		else
			#echo "Found CFBundleIdentifier in: \"${CurrentKextInfoPlistPath}\":${CurrentKextCFBundleIdentifier}"
  			CurrentKextCFBundleVersion="$(/usr/libexec/PlistBuddy -c "Print CFBundleVersion" "${CurrentKextInfoPlistPath}" 2>/dev/null)"
  			if [[ ! "${CurrentKextCFBundleVersion}" ]]
  				then
  					#echo "Not Found CFBundleVersion in: \"${CurrentKextInfoPlistPath}\""
  					let "ErrorsCount+=1"
				else
					#echo "Found: ${CurrentKextCFBundleIdentifier}:${CurrentKextCFBundleVersion}"
					CurrentKext_CodeSignaturePath="${CurrentKextInfoPlistPath/Info.plist/_CodeSignature/CodeResources}"
					let "AllCheckKextsCount+=1"
					#echo "${CurrentKext_CodeSignaturePath}"
					if [[ ! -e "${CurrentKext_CodeSignaturePath}" ]]
						then
							#echo "Found: _CodeSignaturePath for ${CurrentKextCFBundleIdentifier}:${CurrentKextCFBundleVersion}"
							CFBundleVersionFound="$(/usr/libexec/PlistBuddy -c "Print OSKextSigExceptionList:${CurrentKextCFBundleIdentifier}" "${AppleKextExcludeListKextInfoPlistPath}" 2>/dev/null)"
  							if [[ "${CFBundleVersionFound}" ]]
  								then
									#CFBundleVersionFound="$(/usr/libexec/PlistBuddy -c "Print OSKextSigExceptionList:${CurrentKextCFBundleIdentifier} string" "${AppleKextExcludeListKextInfoPlistPath}" 2>/dev/null)"
									#echo "${CFBundleVersionFound}"
  									#printf "${CurrentKextCFBundleIdentifier}:${CFBundleVersionFound} Found\n"
									if ! [[ "${CFBundleVersionFound}" = "${CurrentKextCFBundleVersion}" ]]
										then
											#Result="$(/usr/libexec/PlistBuddy -c "Delete OSKextSigExceptionList:${CurrentKextCFBundleIdentifier}" "${AppleKextExcludeListKextInfoPlistPath}")"
											#printf "Update ${CurrentKextCFBundleIdentifier}:${CFBundleVersionFound} to :${CurrentKextCFBundleVersion} ... "
											Result="$(/usr/libexec/PlistBuddy -c "Set OSKextSigExceptionList:${CurrentKextCFBundleIdentifier} \"${CurrentKextCFBundleVersion}\"" "${AppleKextExcludeListKextInfoPlistPath}")"
											if [[ "${Result}" ]]
												then
													#printf "Error\n"
													let "ErrorsCount+=1"
												else
													#printf "OK\n"
													let "UpdatedUnSigKextsCount+=1"

											fi
									fi
								else
  									#printf "Add ${CurrentKextCFBundleIdentifier}:${CurrentKextCFBundleVersion} ... "
  									Result="$(/usr/libexec/PlistBuddy -c "Add OSKextSigExceptionList:${CurrentKextCFBundleIdentifier} string \"${CurrentKextCFBundleVersion}\"" "${AppleKextExcludeListKextInfoPlistPath}")"
  									if [[ "${Result}" ]]
  										then
  											#printf "Error\n"
  											let "ErrorsCount+=1"
 	 									else
  											#printf "OK\n"
  											let "AddedUnSigKextsCount+=1"
  									fi
							fi
  					fi
			fi
 	fi
	if [ `expr "$AllCheckKextsCount" % 50` -eq "0" ]
		then
			 printf "."
	fi
 	done
finishtime=`date +%s`

IFS=$OldIFS   # return old $IFS

printf " Done.\n"

echo "-- Total processed: (${AllCheckKextsCount} kexts) Added ${AddedUnSigKextsCount}, Updated ${UpdatedUnSigKextsCount} entries for $(($finishtime-$starttime)) sec."
echo
}

PatchKextInfoPlist() {

# Input 1-kext 2-node 3-node value
# Search kext
# If Node exist - Correct node value
# Else Add Node and Set Node value

local KextForPatch="${1}"
local NodeForPatch="${2}"
local NodeValueForPatch="${3}"

local PatchKextPath=`kextfind |grep "${KextForPatch}"` # search kext for patch
#echo "PatchKextPath=${PatchKextPath}"
local PatchKextInfoPlistPath=`find "${PatchKextPath}" -name Info.plist 2>/dev/null` # search kext for patch Info Plist Path

if [[ "${PatchKextInfoPlistPath}" ]] # Check if PatchKext InfoPlist exist
	then
		local PatchKextNodeValue="$(/usr/libexec/PlistBuddy -c "Print ${NodeForPatch}" "${PatchKextInfoPlistPath}" 2>/dev/null)"
		if [[ ! "${PatchKextNodeValue}" ]] || [[ "${PatchKextNodeValue}" != "${NodeValueForPatch}" ]]
			then
cat <<EOF
Task: Patch "${KextForPatch}" Info.plist:
      Set   "${NodeForPatch}" to "${NodeValueForPatch}"
  
EOF
		#echo "Found ${KextForPatch}"
		local PatchKextCFBundleVersion="$(/usr/libexec/PlistBuddy -c "Print CFBundleVersion" "${PatchKextInfoPlistPath}" 2>/dev/null)" # find Kext CFBundleVersion
		echo "Found ${KextForPatch}:CFBundleVersion:$PatchKextCFBundleVersion"

		local BackUpInfoPlist="${PatchKextInfoPlistPath/Info.plist/Info_$PatchKextCFBundleVersion.plist}"
		if [[ ! -e "${PatchKextInfoPlistPath/Info.plist/Info_$PatchKextCFBundleVersion.plist}" ]]
			then
				cp "${PatchKextInfoPlistPath}" "${BackUpInfoPlist}"
				# echo ${A#*AB}
				echo "Backup ${PatchKextInfoPlistPath#*Contents/} to ${BackUpInfoPlist#*Contents/} ... OK"
			else
				echo "Found Backup Info.plist - ${BackUpInfoPlist#*Contents/}"	
		fi
		echo

		if [[ ! "${PatchKextNodeValue}" ]]
			then
				echo "Not Found ${NodeForPatch} in ${PatchKextInfoPlistPath#*Contents/}"
				printf "Add ${NodeForPatch}:${NodeValueForPatch} ... "
				local Result="$(/usr/libexec/PlistBuddy -c "Add ${NodeForPatch} string ${NodeValueForPatch}" "${PatchKextInfoPlistPath}")"
				if [[ "${Result}" ]]
					then
						printf "Error\n"
					else
						printf "OK\n"
				fi
			else
				echo "Found ${NodeForPatch}:${PatchKextNodeValue} in Info.plist"
				#printf "${CurrentKextCFBundleIdentifier}:${CFBundleVersionFound} Found\n"
				if ! [[ "${PatchKextNodeValue}" = "${3}" ]]
					then
						#Result="$(/usr/libexec/PlistBuddy -c "Delete OSKextSigExceptionList:${CurrentKextCFBundleIdentifier}" "${AppleKextExcludeListKextInfoPlistPath}")"
						printf "Update ${NodeForPatch}:${PatchKextNodeValue} to \"${NodeValueForPatch}\" ... "
						Result="$(/usr/libexec/PlistBuddy -c "Set ${NodeForPatch} \"${NodeValueForPatch}\"" "${PatchKextInfoPlistPath}")"
						if [[ "${Result}" ]]
							then
								printf "Error\n"
							else
								printf "OK\n"
						fi
					else
						echo "Nothing to do - patched already"
				fi
		fi
		fi

	else
		#echo "Error ${KextForPatch} not found"
		return 1
fi

echo
}

InstallKext() {

CurrentKext=$1
BaseDropName=$(basename "${CurrentKext}")
DirFilesName="${WorkDir1}"

KextArch=$(kextfind -no-paths "${CurrentKext}" -print0 -echo -n " (arches) " -pa)

cat <<EOF
Task: Install "${KextArch}"
		   to "${WorkDir1}"
 
EOF

	OldIFS=$IFS   # save old $IFS
	IFS=$'\n'     # new $IFS  

    for Files in $(find "${WorkDir1}" -name "${BaseDropName}")
	    do

		DirFilesName=$(dirname "${Files}") 
		printf "Found existing \"${Files}\"\n"
		printf "\n"

		if [ -e "${DirFilesName}/${BaseDropName}.bak" ]
			then
				rm -rf "${DirFilesName}/${BaseDropName}.bak"
		fi

		printf "BackUp : \"${BaseDropName}\" to \"${BaseDropName}.bak\" ... "

		if mv -f "${DirFilesName}/${BaseDropName}" "${DirFilesName}/${BaseDropName}.bak"
			then
				printf "Done.\n"
			else
				printf "Error.\n"
		fi
		printf "\n"

        done
	
	IFS=$OldIFS   # return old $IFS

printf "Install: \"${BaseDropName}\" ... "

if cp -Rf "${CurrentKext}" "${DirFilesName}"
	then
		printf "OK.\n"
	else
		printf "Can't copy source file.\n"
		return 1
fi		

printf "\n"

SetPermissionsMod "${DirFilesName}/${BaseDropName}"
#
touch "${DirFilesName}/${BaseDropName}"

}

saveExit() {

printf "Syncing disk cache ... "
sync
printf "Done.\n"
}

endProgram() {
echo
echo "All done."
echo "Have a nice ... day(night)"
printf "Enjoy ...\n\a"
exit
}

checkFileExist() {

if [[ -e "$1" ]]
	then
	echo "\"$1\" exist"
		return 0
	else
	echo "\"$1\" not exist"
		return 1
fi
}

main() {

if [[ "${kext_msdosfs}" -ne "0" ]] && [[ ${KernOSRelease} -lt "14" ]]
	then
		PatchKextInfoPlist msdosfs.kext OSBundleRequired Console
	else
		if [[ ${KernOSRelease} -lt "14" ]]
			then
				echo "Patch Info.Plist for msdosfs.kext is disabled in KU_config.plist"
				echo
		fi
fi

cat <<EOF
Task: Full service for "${WorkDir1}" and
                       "${WorkDir2}" folders.
         
EOF

if [[ "${kext_AppleKextExcludeList}" -ne "0" ]] && [[ ${KernOSRelease} -lt "14" ]]
	then
		UpdateOSKextSigExceptionList "${WorkDir1}"
	else
		if [[ ${KernOSRelease} -lt "14" ]]
			then
				echo "Update OSKextSigExceptionList is disabled in KU_config.plist"
				echo
		fi
fi

if [[ "$key_v" -ne "0" ]]
	then	
		#echo "key_v="${key_v}
		AddBootArg "-v"
fi

if [[ "${key_kext_dev_mode_1}" -ne "0" ]] && [[ ${KernOSRelease} -ge "14" ]]
	then
		AddBootArg "kext-dev-mode=1"
	else
		if [[ ${KernOSRelease} -ge "14" ]]
			then
				echo "Adding Boot Arg \"kext-dev-mode=1\" is disabled in KU_config.plist"
				echo
		fi
fi


# Must work OK - nothing bad with dir changing
if [ -d "${WorkDir2}" ]
    then
        SetPermissionsMod "${WorkDir2}"
fi

SetPermissionsMod "${WorkDir1}"

# Remove sleepimage file
# if [ -f "/private/var/vm/sleepimage" ]
#     then
#         printf "Preventive removal sleepimage file ... "
#         rm -rf "/private/var/vm/sleepimage"
#         printf "Done.\n"
# 		echo
# fi


# Waiting system rebuild kexts cache

SystemCacheUpdate

echo

}



###############################################
###### Start main script execution routine ####
###############################################

if [ -n "${1}" ]
	then
 		FullDropName="${1}"
 		BaseDropName="$(basename "${FullDropName}")"
 
 		case "${BaseDropName}" in
 			*.mkext)
 				memoMSG
 				SystemSpecMSG
 				StartMSG
#				echo "${BaseDropName}"
 				unpackMkext "${FullDropName}"
 				saveExit
 				endProgram
 				;;
 
 			*.kext|*.ppp|*.plugin|*.bundle)
 				memoMSG
 				SystemSpecMSG
 				StartMSG
				if [[ "${key_v}" -ne "0" ]]
					then
						AddBootArg "-v"
				fi

				if [[ "${key_kext_dev_mode_1}" -ne "0" ]] && [[ ${KernOSRelease} -ge "14" ]]
					then
						AddBootArg "kext-dev-mode=1"
					else
						if [[ ${KernOSRelease} -ge "14" ]]
							then
								echo "Adding Boot Arg \"kext-dev-mode=1\" is disabled in KU_config.plist"
								echo
						fi
				fi
 				i=1
 				while [ $i -le $# ]
 				do
                 	CurrentKext="$(eval "echo \${$i}")"
 					case "$(basename "$CurrentKext")" in
 			    		*.kext|*.ppp|*.plugin|*.bundle)
 							InstallKext "$(eval "echo \${$i}")"
						;;
 					esac
 					i=`expr $i + 1`
 				done
				if [[ "${kext_AppleKextExcludeList}" -ne "0" ]] && [[ ${KernOSRelease} -lt "14" ]]
					then
						UpdateOSKextSigExceptionList "${WorkDir1}"
					else
						if [[ ${KernOSRelease} -lt "14" ]]
							then
								echo "Update OSKextSigExceptionList is disabled in KU_config.plist"
								echo
						fi
				fi
				SystemCacheUpdate
 				echo
 				saveExit
 				endProgram
 				;;
 	
 			*)
             	# if file is directory then pack it
             	if [ -d "$FullDropName" ]
                     then
 				        memoMSG
 				        SystemSpecMSG
 						StartMSG
 				        packMkext "${FullDropName}"
 				        saveExit
 				        endProgram
 				    else
         				memoMSG
         				usage
         				exit
                 fi
                 ;;
 		esac

fi

#echo "Stage If Proceedings"

memoMSG
SystemSpecMSG
StartMSG

CheckConfig

main

saveExit
endProgram