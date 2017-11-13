#!/bin/bash

ELSM_DOCKER_IMAGE="65bdfabdddd6"
ELSM_DOCKER_HOME="$HOME/Desktop/DevOps/servers/salt-master"
ELSM_DOCKER_NAME="salt-master-elsm"
ELSM_DOCKER_PORTS=("4505:4505" "4506:4506")
###If you edit the binds list, make sure they match per array
### ex: "~/foo" added to _FROM array, so "/foo" added to _TO array
ELSM_DOCKER_BINDS_FROM=("${ELSM_DOCKER_HOME}/etc" "${ELSM_DOCKER_HOME}/srv" "${ELSM_DOCKER_HOME}/log" )
ELSM_DOCKER_BINDS_TO=("/etc/salt" "/srv/salt" "/var/log")

###Nothing to see here, DON'T PANIC
ELSM_DOCKER_CMD=`which docker`

check_docker(){
    if [ -z ${ELSM_DOCKER_CMD} ]
    then
        echo "Docker not found: ${ELSM_DOCKER_CMD}"    
        exit 0
    fi
    
    
    test_docker=`${ELSM_DOCKER_CMD} -v`
    if [[ $test_docker =~ "not" ]]
    then
        echo "Problem testing Docker comand: ${ELSM_DOCKER_CMD}"
        exit 0;
    fi
    
    
    echo "Docker found: ${test_docker}"

} 


start_master(){
    start_docker="${ELSM_DOCKER_CMD} start ${ELSM_DOCKER_NAME}"
    start_result=`${start_docker}`
    
    if [[ "$start_result" =~ "No such container" ]]
    then
        echo "Container not found, please use: ${0} build and or update this script"
        echo "Docker Result: {$start_result}"
        exit 0;
    
    fi
    
    
    if [[ -z "$start_result" ]]
    then
        echo "Container not found, please use: ${0} build and / or update this script"
        exit 0;
    
    fi
    
    
    if [ "${start_result}" == "${ELSM_DOCKER_NAME}" ]; then 
        echo "${ELSM_DOCKER_NAME} started!"
        return 1;
    fi
    
    
    echo "Docker Result: ${start_result}"       
        
}


stop_master(){
    stop_docker="${ELSM_DOCKER_CMD} stop ${ELSM_DOCKER_NAME}"
    stop_result=`${stop_docker}`
    kill_docker="${ELSM_DOCKER_CMD} kill ${ELSM_DOCKER_NAME}"
    kill_result=`${kill_docker}`
    
    if [ "${stop_result}" == "${ELSM_DOCKER_NAME}" ]; then 
        echo "${ELSM_DOCKER_NAME} stopped!"
        return 1;
    fi
    
    
    echo "Docker Result: ${stop_result}"
  
}


build_master(){
    
    build_docker="${ELSM_DOCKER_CMD} create"
    for p in "${ELSM_DOCKER_PORTS[@]}"
    do 
        if [[ -z "${p}// }" ]]; then 
            continue;
        fi
        
        
        build_docker+=" -p ${p}"
    
    done
    
    
    build_docker+=" --name ${ELSM_DOCKER_NAME} -h ${ELSM_DOCKER_NAME}"
    mount_docker=""
    
    for i in "${!ELSM_DOCKER_BINDS_FROM[@]}"
    do
        if [[ -z "${ELSM_DOCKER_BINDS_FROM[$i]}// }" ]]; then 
            continue;
        fi
        
        
        if [[ -z "${ELSM_DOCKER_BINDS_TO[$i]}// }" ]]; then 
            continue;
        fi
        
        
        mount_docker+=" -v ${ELSM_DOCKER_BINDS_FROM[$i]}:${ELSM_DOCKER_BINDS_TO[$i]}"
    
    done
    
    
    build_docker+=" ${mount_docker} ${ELSM_DOCKER_IMAGE}"
    build_result=`${build_docker}`
    echo "build cmd: ${build_docker}"
    
    if [[ "${build_result}" =~ "^.*(no such|unable|denied|permission).*$" ]]
    then
        echo "Docker build failed. Result: ${build_result}"
        echo "CMD: ${build_docker}"
        exit 0;
        
    fi
    
    
    if [ ! -z "${build_result}" ]; then 
        echo "${ELSM_DOCKER_NAME} built!"
        echo "New container id: '${build_result}'"
        return 1;
        
    fi
    
    
    echo "Any build errors appear above."

}


mkdir_master(){
    for i in "${ELSM_DOCKER_BINDS_FROM[@]}"
    do
        if [[ -z "${i// }" ]]; then 
            continue;
        fi
            
        #echo "making dir ${i}"
        mk_result=`mkdir -p "${i}"`
    done


}


purge_master(){
    #remove master and all exited containers
    old_dockers=`docker ps -aq -f status=exited`
    purge_dockers=($old_dockers)
    purged=`docker kill ${ELSM_DOCKER_NAME}`
    purged+=`docker rm -f ${ELSM_DOCKER_NAME}`
    
    if [ "${purged}" == "${ELSM_DOCKER_NAME}" ]; then 
        echo "${ELSM_DOCKER_NAME} purged!"
        
    fi
    
    
    #comment here if you what to stop exited container pruning
    for k in "${purge_dockers[@]}"
    do
        purged+=`docker kill ${k}`
        purged+=`docker rm -f ${k}`
        echo "${k} purged"
           
    done
    #end
 
    
    echo "the purge has ended, emergency services restored"
    echo "Purge Results: ${purged}"
    
}

patch_host(){
    #prep
    apt-get update
    apt-get install -y apt-transport-https ca-certificates curl software-properties-common

    #add key
    curl -k -ssl https://repo.saltstack.com/apt/ubuntu/16.04/amd64/latest/SALTSTACK-GPG-KEY.pub | apt-key add -
    curl -k -ssl https://download.docker.com/linux/ubuntu/gpg | apt-key add -
    
    #add repo
    add-apt-repository "deb [arch=amd64] http://repo.saltstack.com/apt/ubuntu/16.04/amd64/latest xenial main"
    add-apt-repository "deb [arch=amd64] https://download.docker.com/linux/ubuntu xenial stable"
    
    #update
    apt-get update
    
    #install 
    apt-get install -y salt-minion salt-common salt-ssh docker-ce

}


check_docker;
mkdir_master;
echo "---Progress / Errors---"
case "$1" in 
    start)   
        echo "starting..." 
        start_master;
        exit 1;
        
    ;;
    
    
    stop)    
        echo "stopping..." 
        stop_master;
        exit 1;
    
    ;;
    
    
    restart) 
        echo "restarting..." 
        stop_master; 
        start_master;
        exit 1;
    
    ;;
    
    
    build)
        echo "building..."
        build_master; 
        echo "starting ..."
        start_master;
        exit 1; 
        
    ;;
    
    
    purge)
        echo "the purge has began..."
        stop_master;
        purge_master;
        exit 1;
    
    ;;
    
    
    patch)
        echo "Installing salt and docker..."
        patch_host;
        exit 1;
        
        
    ;;
    
    
    *)
        echo "Usage: $0 start|stop|restart|build|purge|patch"
        echo "must edit config items ELSM_DOCKER_IMAGE and ELSM_DOCKER_FILEDIR in script to use"
        echo "purge will delete all exited containers (use with caution)"
        echo "patch will attempt to install salt and docker repo's and packages"
        exit 1;
    
        
esac
exit 0
