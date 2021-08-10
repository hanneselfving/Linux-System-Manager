#!/bin/bash
#Hannes Elfving & Joel Oyola
#Projektgrupp P36
#Course Code: DVA249


RED='\033[0;31m'
YELLOW='\033[1;33m'
NC='\033[0m'

pressTo()
{
echo -n "Press a key to continue..."
read temp
}
#===================================
networkInfo()
{
cName=$(hostname)
ip=$(ip addr show scope global | awk '$1 ~ /^inet/ {print $2; exit}')
mac=$(ip addr show scope global | awk '$1 ~ /^link/ {print $2; exit}')
gWay=$(ip route show | awk '/^default/ {print $3}')
status=$(ip addr show scope global | awk '/state/ {print $9; exit}')
iFace=$(ip link show | grep ^[2-999] | cut -d: -f2 | tr '\n' ', ' | sed 's/,$//g' | sed 's/ //g')

echo -e "${YELLOW}\t\t***********Network Information***********"
echo -e "${RED}Computer Name: \t\t${NC}$cName"
echo -e "${RED}Interface(s):\t\t${NC}$iFace"
echo -e "${RED}IP: \t\t\t${NC}$ip"
echo -e "${RED}MAC: \t\t\t${NC}$mac"
echo -e "${RED}Status: \t\t${NC}$status"
echo -e "${RED}Gateway: \t\t${NC}$gWay"
echo -e "\t\t${YELLOW}*****************************************${NC}"
}
#===================================
userAdd()
{
echo -e "${YELLOW}\t\t***********User Add***********${NC}"
echo -n "Enter username: "
read uName

if [ -z $uName ]
then
echo "Name field can't be empty!"
return
fi

echo -n "Enter pass (or no pass if desired): "
read pass

if [ -z $pass ]
then
if (useradd -m -d /home/$uName -s /bin/bash -c "Added with UserAdd.bash" $uName)
then
echo "User $uName added with no password."
else
echo "Error."
fi

elif (useradd -m -d /home/$uName -s /bin/bash -c "Added with UserAdd.bash" -p $pass  $uName)
then
echo "User $uName added with password."
else
echo "Error"

fi
}
#===================================
userMod()
{
echo -e "${YELLOW}\t\t***********User Modify***********${NC}"

echo -n "Enter username: "
read uName

if ! id $uName > /dev/null 2>&1
then
	echo "error, user does not exist."
	return
fi

if [[ -z $uName ]]
then
echo No username entered.
return
fi

echo enter one of the following options
echo "p for password change"
echo "n for name change"
echo "uid for user id change"
echo "g for primary group change"
echo "c to change comment"
echo "h to change home folder"
echo "sh to change shell path"
read opt

if [[ $opt == "p" ]]
then

passwd $uName && echo "success" || echo "error"

elif [[ $opt == "n" ]]
then
echo Enter new username:
read newName

usermod -l $newName $uName
hPath="/home/$newName"
usermod -d $hPath -m $newName


elif [[ $opt == "uid" ]] #user id
then
echo Enter ID
read uid
usermod -u $uid $uName 

elif [[ $opt == "g" ]] #primary group
then
echo Enter group name or group ID
read grp
usermod -g $grp $uName 

elif [[ $opt == "c" ]] #comment
then
echo Enter comment
read cmt
usermod -c $cmt $uName

elif [[ $opt == "h" ]] #home folder
then
echo Enter path where new home directory will be created
read hPath
usermod -d $hPath -m $uName

elif [[ $opt == "sh" ]] #shell path
then
echo enter path of shell
read sPath
usermod --shell $sPath $uName

else
echo Error, invalid input
fi

}
#===================================
userView()
{
echo -e "${YELLOW}\t\t***********User View***********${NC}"
echo -n "Enter username: "
read uName
src=/etc/passwd

if grep -q "^$uName:.*" /etc/passwd; then
if [ -z "$uName" ]
then
	echo "UserView: Error"
else
	line=$(grep "^$uName:" $src)
	groups=$(groups $uName | cut -d: -f2)
	uid=$(echo "$line" | cut -d: -f3)
	grp=$(echo "$line" | cut -d: -f4)
	cmt=$(echo "$line" | cut -d: -f5)
	hm=$(echo "$line" | cut -d: -f6)
	sh=$(echo "$line" | cut -d: -f7)
	printf "Username: "
	echo "$line" | cut -d: -f1
	echo Groups: $groups
	echo User ID: $uid
	echo Primary Group: $grp
	echo Comment: $cmt
	echo Home Directory: $hm
	echo Shell Path: $sh
fi
else
	echo "Error"
fi
}
#===================================
userList()
{
echo -e "${YELLOW}\t\t***********User List***********${NC}"
echo -e "USERNAME | PASS | UID | GID | COMMENT | HOME | SHELL"
echo " "
cat /etc/passwd | sed 's/:/ /g' | awk '$3 > 999'
}
#===================================
userDel()
{
echo -e "${YELLOW}\t\t***********User Delete***********${NC}"
echo -n "Enter username: "
read uName

if [ -z $uName ]
then
echo "Error"
else
userdel -r $uName 2> /dev/null
echo "User deleted successfully"
fi
}
#===================================
groupAdd()
{
	echo -e "${YELLOW}\t\t***********Group Add***********${NC}"
	echo -n "Type a name for the new group: "
	read name
	if [[ -z $name ]]; then
		echo "Error"
		return
	fi

	if [[ ! $name =~ ^[_a-z].* ]]; then
		echo "Name needs to start with a small letter or underscore(_). "
	elif [[ $name =~ .*-$ ]]; then
		echo "Name can't end with a slash(-)."
	elif [[ `echo $name | wc -c` -gt 16 ]]; then
		echo "The length of the name needs to be less than 16 characters."
	else
		temp=`cat /etc/group | grep "^$name"`

		if [[ -z "$temp" ]];then
			groupadd $name
			echo "Group $name added successfully."
		else
			echo "Group already exists."
		fi
	fi
}
#===================================
groupMod()
{
	echo -e "${YELLOW}\t\t***********Group Modify***********${NC}"
	echo -n "Which group do you want to modify? "
	read group

	#If group exists
	if grep -q "^$group:.*" /etc/group; then
		echo -n "Do you want to add(a) or remove(r) a user from this group? "
		read option

		while [ "$option" != "a" ] && [ "$option" != "r" ]
		do
			echo -n "Please type a valid option (a to add or r to remove): "
			read option
		done

		if [[ "$option" == "a" ]]; then
			echo -n "User to add to the group: "
			read user

			#If user exist
			if grep -q "^$user" /etc/passwd; then

				temp=`grep "^$group" /etc/group | grep $user`
				#If user is not a member of the group
				if [[ -z "$temp" ]]; then
					usermod -aG $group $user
					echo "User added successfully."

				#If user is already a member of the group
				else
					echo "User is already a member of this group."
				fi
			#If user doesn't exist
			else
				echo "Username $user doesn't exist."
			fi

		elif [[ "$option" == "r" ]]; then
			echo -n "User to remove from the group: "
			read user
			#If user exist
			if grep -q "^$user" /etc/passwd; then
				temp=`grep "^$group" /etc/group | grep $user`

				if [[ -n "$temp" ]]; then
					deluser $user $group 1> /dev/null
					echo "User removed successfully."
				else
					echo "User is not a member of this group."
				fi
			#If user doesn't exist
			else
				echo "Username $user doesn't exist."
			fi
		fi
	#If group doesn't exist
	else
		echo "Group doesn't exist."
	fi
}
#===================================
groupView()
{
	echo -e "${YELLOW}\t\t***********Group View***********${NC}"
	echo -n "Which group do you want to view? "
	read name

	if grep -q "^$name:" /etc/group; then
		echo "Members of the group $name:"
		temp=`cat /etc/group | grep "^$name" | cut -d : -f4 | sed 's/,/\n/g'`

		if [[ -n "$temp" ]]; then
			echo "$temp"
		else
			echo "Group is empty."
		fi
	else
		echo "Group doesn't exist."
	fi
}
#===================================
groupList()
{
	echo -e "${YELLOW}\t\t***********Group List***********${NC}"
	echo "Listing all groups: "
	cat /etc/group | sed 's/:/ /g' | awk '$3 > 999' | sed 's/ .*/ /g'
}
#===================================
groupDel()
{
	echo -e "${YELLOW}\t\t***********Group Delete***********${NC}"
	echo -n "Which group would you like to delete? "
	read option

	if grep -q "^$option:" /etc/group; then
		temp=`cat /etc/group | grep "^$option" | sed 's/:/ /g' | awk '$3 > 999'`
		if [[ -n "$temp" ]]; then
			groupdel $option
			echo "Group deleted successfully."
		else
			echo "Can't delete system groups!"
		fi
	else
		echo "Group doesn't exist."
	fi
}
#===================================
folderAdd()
{
	echo -e "${YELLOW}\t\t***********Folder Add***********${NC}"
	echo -n "Name for the new directory: "
	read name

	if [[ "$name" =~ .*/.* ]]; then
		echo "Name can't contain the symbol /"
		echo -n "Do you want to try again? (y/n): "
		read answer
		regex="[yn]"
		while [[ ! "$answer" =~ $regex ]]
		do
			echo "Please try again: "
			read answer
		done

		if [[ "$answer" == "y" ]]; then
			folderAdd
		fi

	else
		user=`who | cut -d ' ' -f1`
		temp=$(mkdir /home/"$user"/"$name" &> /dev/null)
		echo "Folder created successfully."
	fi
}
#===================================
folderMod()
{
echo -e "${YELLOW}\t\t***********Folder Modify***********${NC}"
echo -n "Enter path to target file: "
read path

if [ ! -d "$path" ] 
then
	echo "Error. Path does not exist"
	return
fi

echo Enter...
echo 1. to change ownership
echo 2. to change permissions
echo 3. to set GID
echo 4. to set stickybit
echo 5. to modify date
read opt

if [[ $opt == "1" ]] #Ownership
then

echo enter username 
read uName

if [[ -z $uName ]]
then
echo No username entered.
return
fi

chown $uName $path && echo "Ownership changed" || echo "Error"

elif [[ $opt == "2" ]] #Permissions
then

echo Who shall be permitted to view  file?
echo "Owner? (y/n)"
read answer
if [[ $answer == "y" ]]
then
	chmod u+r $path
elif [[ $answer == "n" ]]
then
	chmod u-r $path
else
echo Error
return
fi
echo "Group? (y/n)"
read answer
if [[ $answer == "y" ]]
then
	chmod g+r $path
elif [[ $answer == "n" ]]
then
	chmod g-r $path
else
echo Error
return
fi
echo "Others? (y/n)"
read answer
if [[ $answer == "y" ]]
then
	chmod o+r $path
elif [[ $answer == "n" ]]
then
	chmod o-r $path
else
echo Error
return
fi
echo Who shall be permitted to edit file?
echo "Owner? (y/n)"
read answer
if [[ $answer == "y" ]]
then
	chmod u+w $path
elif [[ $answer == "n" ]]
then
	chmod u-w $path
else
echo Error

fi
echo "Group? (y/n)"
read answer
if [[ $answer == "y" ]]
then
	chmod g+w $path
elif [[ $answer == "n" ]]
then
	chmod g-w $path
else
echo Error

fi
echo "Others? (y/n)"
read answer
if [[ $answer == "y" ]]
then
	chmod o+w $path
elif [[ $answer == "n" ]]
then
	chmod o-w $path
else
echo Error
return
fi
echo Who shall be permitted to execute file?
echo "Owner? (y/n)"
read answer
if [[ $answer == "y" ]]
then
	chmod u+x $path
elif [[ $answer == "n" ]]
then
	chmod u-x $path
else
echo Error
return
fi
echo "Group? (y/n)"
read answer
if [[ $answer == "y" ]]
then
	chmod g+x $path
elif [[ $answer == "n" ]]
then
	chmod g-x $path
else
echo Error
return
fi
echo "Others? (y/n)"
read answer
if [[ $answer == "y" ]]
then
	chmod o+x $path
elif [[ $answer == "n" ]]
then
	chmod o-x $path
else
echo Error
return
fi

elif [[ $opt == "3" ]] #SetGID
then
	echo Enter Group
	read grp
	chgrp $grp $path && echo "Ownership changed" || echo "Error"
	chmod g+s $path

elif [[ $opt == "4" ]] #Stickybit
then
	chmod +t $path	

elif [[ $opt == "5" ]] #Modify date
then
	echo "Enter Date (yyyymmddtttt)"
	read date
	touch -m -t $date $path
fi

}
#===================================
checkPermissions()
{
	arg1=$1
	arg2=$2
	echo "$arg1"
	if [[ "$arg1" =~ .*w.* ]]; then
		echo -n "write "
	fi
	if [[ "$arg1" =~ ^r.* ]]; then
		echo -n "read "
	fi
	if [[ "$arg1" =~ .*x ]]; then
		echo -n "execute "
	elif [[ "$arg1" =~ .*s ]] && [[ "$arg2" == "1" ]]; then
		echo -n "setuid (files with this permission will be run as owner of the file) execute"
	elif [[ "arg1" =~ .*S ]] && [[ "$arg2" == "1" ]]; then
		echo -n "setuid (files with this permission will be run as owner of the file) "
	elif [[ "$arg1" =~ .*s ]] && [[ "$arg2" == "2" ]]; then
		echo -n "setgid (files created here inherit directory's permissions) execute "
	elif [[ "$arg1" =~ .*S ]] && [[ "$arg2" == "2" ]]; then
		echo -n "setgid (files created here inherit directory's permissions) "
	elif [[ "$arg1" =~ .*t ]] && [[ "$arg2" == "3" ]]; then
		echo -n "sticky bit (Only owner of the file can rename and delete it) execute "
	elif [[ "$arg1" =~ .*T ]] && [[ "$arg2" == "3" ]]; then
		echo -n "sticky bit (Only owner of the file can rename and delete it) "
	fi
}
#===================================
checkType()
{
	arg1=$1
	if [[ "$arg1" == "d" ]]; then
		echo "Directory"
	elif [[ "$arg1" == "-" ]]; then
		echo "Regular file"
	elif [[ "$arg1" == "l" ]]; then
		echo "Symbolic link"
	fi
}
#===================================
folderView()
{
	echo -e "${YELLOW}\t\t***********Folder View***********${NC}"
	echo "Available folders: "
	name=`who | cut -d ' ' -f1`
	echo /home/"$name"/*/ | sed 's/ /\n/g' | cut -d / -f4
	echo -n -e "Which folder do you want to view?\nType one of these folders or type a full path to the directory you want to view: "
	read -r folder

	if [[ "$folder" =~ .*/.* ]] && [[ -d "$folder" ]]; then
		type=$(ls -ld "$folder" | cut -c1)
		userPer=`ls -l -d "$folder" | cut -c2-4`
		groupPer=`ls -l -d "$folder" | cut -c5-7`
		othersPer=`ls -l -d "$folder" | cut -c8-10`
	elif [[ -d /home/"$name"/"$folder" ]]; then
		type=$(ls -ld /home/"$name"/"$folder" | cut -c1)
		userPer=`ls -l -d /home/"$name"/"$folder" | cut -c2-4`
		groupPer=`ls -l -d /home/"$name"/"$folder" | cut -c5-7`
		othersPer=`ls -l -d /home/"$name"/"$folder" | cut -c8-10`
	else
		echo "Directory doesn't exist."
		return
	fi

		echo "Folder name: $folder"
	echo -n "Type: "
	checkType "$type"
	echo -n "User permissions: "
	checkPermissions "$userPer" "1"
	echo " "
	echo -n "Group permissions: "
	checkPermissions "$groupPer" "2"
	echo " "
	echo -n "Permissions for the rest: "
	checkPermissions "$othersPer" "3"
	echo " "
}
#===================================
folderList()
{
	echo -e "${YELLOW}\t\t***********Folder List***********${NC}"
	echo -n "Give a path to the folder you want to list or press enter to show home directory's folders: "
	read folder

	if [[ -z $folder ]]; then
		echo "Listing all folders in home directory..."
		name=`who | cut -d ' ' -f1`
		echo /home/"$name"/*/ | sed 's/ /\n/g' | cut -d / -f4
	elif [[ "$folder" =~ .*/.* ]] && [[ -d "$folder" ]]; then
		echo "Showing folder's contents..."
		ls $folder
	else
		echo "Error."
	fi
	
}
#===================================
folderDel()
{
echo -e "${YELLOW}\t\t***********Folder Delete***********${NC}"
echo -n "Enter Path: "
read path

if [ -z $path ]
then
echo "Error"
else
rm -r $path && echo "Success"
fi
}
#===================================
#===================================
#===================================
optionVar=""


if [[ $EUID -ne 0 ]]; then
echo Error, try using sudo
return
fi

while [[ $optionVar != "ex" ]]
do
	
	clear
	echo "****************************"
	echo -e "\\t${YELLOW}SYSTEM MANAGER"
	echo -e "${NC}----------------------------"

	echo -e "${RED}ni ${NC}- Network Information"
	echo
	echo -e "${RED}ua ${NC}- User Add"
	echo -e "${RED}ul ${NC}- User List"
	echo -e "${RED}uv ${NC}- User View"
	echo -e "${RED}um ${NC}- User Modify"
	echo -e "${RED}ud ${NC}- User Delete"
	echo 
	echo -e "${RED}ga ${NC}- Group Add"
	echo -e "${RED}gl ${NC}- Group List"
	echo -e "${RED}gv ${NC}- Group View"
	echo -e "${RED}gm ${NC}- Group Modify"
	echo -e "${RED}gd ${NC}- Group Delete"
	echo 
	echo -e "${RED}fa ${NC}- Folder Add"
	echo -e "${RED}fl ${NC}- Folder List"
	echo -e "${RED}fv ${NC}- Folder View"
	echo -e "${RED}fm ${NC}- Folder Modify"
	echo -e "${RED}fd ${NC}- Folder Delete"
	echo
	echo -e "${RED}ex ${NC}- Exit"
	echo "-------------------------"
	echo -n  "Choice: "
	read optionVar
	clear

if [[ $optionVar == "ni" ]]
	then
		networkInfo
	elif [[ $optionVar == "ua" ]]
	then
		userAdd
	elif [[ $optionVar == "ul" ]]
	then
		userList
	
	elif [[ $optionVar == "uv" ]]
	then
		userView
	
	elif [[ $optionVar == "um" ]]
	then
		userMod
	
	elif [[ $optionVar == "ud" ]]
	then
		userDel
	
	elif [[ $optionVar == "ga" ]]
	then
		groupAdd
	
	elif [[ $optionVar == "gl" ]]
	then
		groupList
	
	elif [[ $optionVar == "gv" ]]
	then
		groupView
	
	elif [[ $optionVar == "gm" ]]
	then
		groupMod
	
	elif [[ $optionVar == "gd" ]]
	then
		groupDel
	
	elif [[ $optionVar == "fa" ]]
	then
		folderAdd
	
	elif [[ $optionVar == "fl" ]]
	then
		folderList
	
	elif [[ $optionVar == "fv" ]]
	then
		folderView
	
	elif [[ $optionVar == "fm" ]]
	then
		folderMod
	
	elif [[ $optionVar == "fd" ]]
	then
		folderDel
	fi
	read -p "Press enter to continue..."
done
