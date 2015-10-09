#!/bin/bash

#Set up some format
red='\e[31m'
yellow='\e[33m'
green='\e[32m'
grey='\e[90m'
bold='\e[1m'
blink='\e[5m'
reset='\e[0m'

ACTION=$1
if [ -z "${ACTION}" ]; then
  echo -e "${red}ERROR: Action not supplied${reset}"
  echo -e 'USAGE: kickme (reinstall|decommission)'
  exit
fi

if [ "${ACTION}" != "reinstall" ] && [ "${ACTION}" != "decommission" ]; then
  echo -e "${red}ERROR: ${ACTION} is not a valid action${reset}"
  echo -e 'USAGE: kickme (reinstall|decommision)'
  exit
fi

#MAIN LINE
echo -e "${red}${bold}${blink}WARNING WARNING WARNING${reset}"
echo -e "${yellow}You are about to destroy this machine!!${reset}"
echo -e "Type the FQDN name of the machine you are intending to ${green}${ACTION}${reset}:"
read CONFIRM

CERTNAME=`facter fqdn`

if [ "${CONFIRM}" == "${CERTNAME}" ]; then
  echo "${ACTION}ing ${CERTNAME}!!!"
  echo "${ACTION}=${CERTNAME}" > /etc/facter/facts.d/decom.txt
  echo "Running Puppet to ${ACTION} the machine.  The machine will go down during the Puppet run!"
  puppet agent -t
else
  echo -e "${red}ERROR: This machine is not ${CONFIRM}${reset}"
  exit
fi
