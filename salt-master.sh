#!/bin/bash

ELSM_DOCKER_IMAGE="a2f03f6d5c5a"
ELSM_DOCKER_FILE="."
ELSM_DOCKER_NAME="salt-master-elsm"
ELSM_DOCKER_PORTS=("4505:4505" "4506:4506")
###If you edit the binds list, make sure they match per array
### ex: "~/foo" added to _FROM array, so "/foo" added to _TO array
ELSM_DOCKER_BINDS_FROM=("$HOME/Desktop/DevOps/servers/salt-master/etc" "$HOME/Desktop/DevOps/servers/salt-master/srv" "$HOME/Desktop/DevOps/servers/salt-master/log" )
ELSM_DOCKER_BINDS_TO=("/etc/salt" "/srv" "/var/log")


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
    
    echo "Docker tested. Result: ${test_docker}"

} 


start_master(){
    start_docker="${ELSM_DOCKER_CMD} start ${ELSM_DOCKER_NAME}"
    start_result=`${start_docker}`
    if [[ $start_result =~ "No such container" ]]
    then
        echo "Container not found, please use: ${0} build and update this script\n Result: {$start_result}"
        exit 0;
    fi
    
    echo "Docker started. Result: ${start_result}"
    exit 1;        
        
}

stop_master(){
    stop_docker="${ELSM_DOCKER_CMD} stop ${ELSM_DOCKER_NAME}"
    stop_result=`${stop_docker}`
    echo "Docker stopped. Result: ${stop_result}"
    exit 1;

}

build_master(){
    
    build_docker="${ELSM_DOCKER_CMD} create"
    for p in "${ELSM_DOCKER_PORTS[@]}"
    do 
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
    
    #on failure outputs regardless
    #if [[ "${build_result}" =~ "^.*(no such|unable|denied|permission).*$" ]]
    #then
    #    echo "Docker build failed. Result: ${build_result}"
    #    echo "CMD: ${build_docker}"
    #    exit 0;
        
    #fi
    
    echo "Any Docker errors appear above. New container id: '${build_result}'"
    echo "CMD: ${build_docker}" 
    exit 1;

}

mkdir_master(){
    for i in "${ELSM_DOCKER_BINDS_FROM[@]}"
    do
        if [[ -z "${i// }" ]]; then 
            continue;
        fi
            
        echo "making dir ${i}"
        mk_result=`mkdir -p "${i}"`
    done

}

purge_master(){
    #remove master and all exited containers
    old_dockers=`docker ps -aq -f status=exited`
    purge_dockers=($old_dockers)
    purged=`docker kill ${ELSM_DOCKER_NAME}`
    purged+=`docker rm ${ELSM_DOCKER_NAME}`
    
    for k in "${purge_dockers[@]}"
    do
        purged+=`docker kill -f ${k}`
        purged+=`docker rm ${k}`
           
    done
}

check_docker;
mkdir_master;

case "$1" in 
    start)   
        echo "start" 
        start_master;
        
    ;;
    
    stop)    
        echo "stop" 
        stop_master;
    
    ;;
    
    restart) 
        echo "restart" 
        stop_master; 
        start_master;
        
    ;;
    
    build)
        echo "build"
        build_master;  
        
    ;;
    
    purge)
        echo "purge"
        purge_master;
        
    ;;
    
    *)
        echo "Usage: $0 start|stop|restart|build|purge"
        echo "must edit config items ELSM_DOCKER_IMAGE and ELSM_DOCKER_FILE in script to use"
        echo "purge will delete all exited containers (use with caution)"
        exit 1
        
esac
#exit 0

