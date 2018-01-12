#!/bin/bash
log() {
    echo -ne "\e[1;34mA2DPSOURCE \e[m" >&2
    echo -e "[`date`] $@"
}
installlog() {
    echo -ne "\e[1;34mA2DPSOURCE \e[m" >&2
    echo -e "$@"
}
YesNo() {
        # Usage: YesNo "prompt"
        # Returns: 0 (true) if answer is Yes
        #          1 (false) if answer is No
        while true
        do
                read -p "$1" answer
                case "$answer" in
                [nN]*)
                        answer="1"; break;
                ;;
                [yY]*)
                        answer="0"; break;
                ;;
                *)
                        echo "Please answer y or n"
                ;;
                esac
        done
        return $answer
}
verify() {
    if [ $? -ne 0 ]; then
        echo "Fatal error encountered: $@"
        exit 1
    fi
}
tst() {
        echo "===> Executing: $*"
        if ! $*; then
                echo "Exiting script due to error from: $*"
                exit 1
        fi
}

apt_install() {
    log Checking $1...
    INSTALLED=`dpkg -l $1 | grep ii`
    if [ "$INSTALLED" ]
    then
        log Dependency $1 already met...
    else
        log Installing $1...    
        $INSTALL_COMMAND $1
        verify "Installation of package '$1' failed"
        echo $1 >> "$A2DPSOURCE_PATH/installed_deps"
        verify "Adding package '$1'to $A2DPSOURCE_PATH/installed_deps failed"        
    fi
}
run(){
   log Running $*...
   $*
   verify "$* failed"
}
exc(){
    log Executing $*
    $* &> /dev/null
    verify "'$*' failed"
}
apt_update() {
    log Updating via $*...
    $*
    verify "'$*' failed"
}
apt_upgrade() {
    log Upgrading via $*...
    $*
    verify "'$*' failed"
}

remove_dir(){
    if [ -e "$1" ]; then 
        if [ -d "$1" ]; then 
            sudo rm -R $1
        else 
            log $1 is not a directory
        fi
    fi
}
remove_file(){
    if [ -e "$1" ]; then 
        if [ -d "$1" ]; then 
            sudo rm -R $1
        else 
            sudo rm -f $1
        fi
    fi
}
restore_originals(){
    if [ -e "$A2DPSOURCE_BACKUP_PATH/files" ]; then 
        if [ -d "$A2DPSOURCE_BACKUP_PATH/files" ]; then 
            log "Unable to Restore Original Files, $A2DPSOURCE_BACKUP_PATH/files is a directory" 
            
        else 
            log Restoring Original Files...
            while IFS='' read -r line || [[ -n "$line" ]]; do
            FILE=`echo $line | sed "s/=.*//"`
            DIR=`echo $line | sed "s/.*=//"`
            FINAL="$DIR/$FILE"
            log Restoring $FILE to "$FINAL"
            sudo cp "$A2DPSOURCE_BACKUP_PATH/$FILE" $FINAL
            done < "$A2DPSOURCE_BACKUP_PATH/files"
        fi
    else
        log "Unable to Restore Original Files, $A2DPSOURCE_BACKUP_PATH/files doesn't exist" 
    fi
    
}
save_original(){
    if [ -e "$1" ]; then
        if [ -d "$1" ]; then
            log "$1 is  a directory"
        else

            FILE=`echo $1 | sed "s/.*\///"`
            echo $FILE
            LOC="$A2DPSOURCE_BACKUP_PATH/$FILE"
            if [ -e "$LOC" ]
            then
                log "File '$FILE' has been previously backed up"
            else
                log Saving $1...
                DIR=`dirname "$1"`
                DIR="$DIR/"
                DIRFINAL="$A2DPSOURCE_BACKUP_PATH/files"
                echo "$FILE=$DIR" | sudo tee -a "$DIRFINAL"
                sudo cp $1 "$LOC"
            fi
        fi
    else
        log "$1 does not exist"
    fi

}
UNINSTALL_COMMAND="sudo apt-get remove -y"
apt_uninstall(){
    log Checking $1 for system dependency...
    while IFS='' read -r line || [[ -n "$line" ]]; do
        if [ "$line" = "$1" ]
        then
            INSTALLED=`dpkg -l $1 | grep ii`
            if [ "$INSTALLED" ]
            then
                log Uninstalling $1...
                $UNINSTALL_COMMAND $1 &> /dev/null
            else  
                log Package $1 was not installed, continuing...
            fi
            break
        fi
    done < "$A2DPSOURCE_PATH/installed_deps"
    verify "Installation of package '$1' failed"
}
rem_files(){
    log "Removing File $1..."
    sudo rm $1
    verify "Removal of file '$1' failed"
}
rem_dir(){
    log "Removing Directory $1..."
    sudo rm -R $1
    verify "Removal of directory '$1' failed"
}
uninstall_bluetooth(){
    source $A2DPSOURCE_PATH/dependencies.sh
    for _dep in ${BT_DEPS[@]}; do
        apt_uninstall $_dep;
    done     
    sudo update-rc.d pulseaudio remove
    sudo update-rc.d bluetooth-agent remove
    sudo rm -R ~/pulseaudio
    sudo rm -R ~/libsndfile
    sudo rm -R ~/json-c
    cd $A2DPSOURCE_PATH
}

