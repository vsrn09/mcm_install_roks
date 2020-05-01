# ---------------------------------------------------------------------------------------------------------------------------------------------------"
# ---------------------------------------------------------------------------------------------------------------------------------------------------"
# ---------------------------------------------------------------------------------------------------------------------------------------------------"
# Install Script for Terraform & Service Automation Module (CAM) 
#
# V1.0 
#
# ©2020 nikh@ch.ibm.com
# ---------------------------------------------------------------------------------------------------------------------------------------------------"
# ---------------------------------------------------------------------------------------------------------------------------------------------------"
# ---------------------------------------------------------------------------------------------------------------------------------------------------"
# ---------------------------------------------------------------------------------------------------------------------------------------------------"

source ./0_variables.sh

HELM_RELEASE_NAME=cam-helm

# ---------------------------------------------------------------------------------------------------------------------------------------------------"
# ---------------------------------------------------------------------------------------------------------------------------------------------------"
# Do Not Edit Below
# ---------------------------------------------------------------------------------------------------------------------------------------------------"
# ---------------------------------------------------------------------------------------------------------------------------------------------------"
echo "${GREEN}***************************************************************************************************************************************************${NC}"
echo "${GREEN}***************************************************************************************************************************************************${NC}"
echo "${GREEN}***************************************************************************************************************************************************${NC}"
echo " ${CYAN}${rocket}  Cloud Pak for Multicloud Management${NC}"
echo "${GREEN}***************************************************************************************************************************************************${NC}"
echo "  "
echo " ${CYAN} Install Terraform & Service Automation Module (CAM) for OpenShift 4.3${NC}"
echo "  "
echo "${GREEN}***************************************************************************************************************************************************${NC}"
echo "${GREEN}***************************************************************************************************************************************************${NC}"
echo "${GREEN}***************************************************************************************************************************************************${NC}"
echo "  "
echo "  "
echo "  "



# ------------------------------------------------------------------------------------------------------------------------------------------------------------------------
# ------------------------------------------------------------------------------------------------------------------------------------------------------------------------
# GET PARAMETERS
# ------------------------------------------------------------------------------------------------------------------------------------------------------------------------
# ------------------------------------------------------------------------------------------------------------------------------------------------------------------------
echo "${CYAN}***************************************************************************************************************************${NC}"
echo "${CYAN}---------------------------------------------------------------------------------------------------------------------------${NC}"
echo " ${PURPLE}${magnifying} Input Parameters${NC}"
echo "${CYAN}---------------------------------------------------------------------------------------------------------------------------${NC}"

        while getopts "t:d:h:p:s:x:" opt
        do
          case "$opt" in
              t ) INPUT_TOKEN="$OPTARG" ;;
              d ) INPUT_PATH="$OPTARG" ;;
              h ) INPUT_CLUSTER_NAME="$OPTARG" ;;
              p ) INPUT_PWD="$OPTARG" ;;
              s ) INPUT_SC="$OPTARG" ;;
              x ) INPUT_CONSOLE_PREFIX="$OPTARG";;
          esac
        done



        if [[ $INPUT_TOKEN == "" ]];
        then
        echo "    ${RED}ERROR${NC}: Please provide the Registry Token"
        echo "    USAGE: $0 -t <REGISTRY_TOKEN> -x <OCP_CONSOLE_PREFIX> [-h <CLUSTER_NAME>] [-p <MCM_PASSWORD>] [-d <TEMP_DIRECTORY>] [-s <STORAGE_CLASS>]"
        exit 1
        else
          echo "    ${GREEN}Token OK:${NC}                           '$INPUT_TOKEN'"
          ENTITLED_REGISTRY_KEY=$INPUT_TOKEN
        fi


        if [[ $INPUT_CONSOLE_PREFIX == "" ]];
        then
            echo "    ${RED}ERROR${NC}: Please provide the OCP console prefix (for example console)"
            echo "    USAGE: $0 -t <REGISTRY_TOKEN> -x <OCP_CONSOLE_PREFIX> [-h <CLUSTER_NAME>] [-p <MCM_PASSWORD>] [-d <TEMP_DIRECTORY>] [-s <STORAGE_CLASS>]"
            exit 1
        else
          echo "    ${GREEN}Console Prefix OK:${NC}                  '$INPUT_CONSOLE_PREFIX'"
          OCP_CONSOLE_PREFIX=$INPUT_CONSOLE_PREFIX
        fi



        if [[ ($INPUT_CLUSTER_NAME == "") ]];
        then
          echo "    ${ORANGE}No Cluster Name provided${NC}            ${GREEN}will be determined from Kubeconfig${NC}"
        else
          echo "    ${GREEN}Cluster OK:${NC}                           '$INPUT_CLUSTER_NAME'"
          CLUSTER_NAME=$INPUT_CLUSTER_NAME
        fi



        if [[ $INPUT_PWD == "" ]];          
        then
          echo "    ${ORANGE}No Password provided, using${NC}         '$MCM_PWD'"
        else
          echo "    ${GREEN}Password OK:${NC}                        '********'"
          MCM_PWD=$INPUT_PWD
        fi



        if [[ $INPUT_PATH == "" ]];
        then
          echo "    ${ORANGE}No Path provided, using${NC}             '$TEMP_PATH'"
        else
          echo "    ${GREEN}Path OK:${NC}                            '$INPUT_PATH'"
          TEMP_PATH=$INPUT_PATH
        fi


        if [[ ($INPUT_CLUSTER_NAME == "") ]];
        then
          getClusterFQDN
          #CLUSTER_FQDN=$? 
        fi


        if [[ $INPUT_SC == "" ]];
        then
          echo "    ${ORANGE}No Storage Class provided, using${NC}    '$STORAGE_CLASS_BLOCK' and '$STORAGE_CLASS_FILE'"
        else
          echo "    ${GREEN}Storage Class OK:${NC}                   '$INPUT_SC'"
          STORAGE_CLASS_BLOCK=$INPUT_SC

          if [[ $CLUSTER_NAME =~ "fyre.ibm.com" ]];
          then
            STORAGE_CLASS_FILE=rook-ceph-cephfs-internal
          else
            STORAGE_CLASS_FILE=$(echo $STORAGE_CLASS_BLOCK | ${SED} "s/block/file/")
          fi

        fi
echo "${CYAN}---------------------------------------------------------------------------------------------------------------------------${NC}"
echo "${CYAN}***************************************************************************************************************************${NC}"
echo "  "
echo "  "
echo "  "
echo "  "




# ------------------------------------------------------------------------------------------------------------------------------------------------------------------------
# ------------------------------------------------------------------------------------------------------------------------------------------------------------------------
# PRE-INSTALL CHECKS
# ------------------------------------------------------------------------------------------------------------------------------------------------------------------------
# ------------------------------------------------------------------------------------------------------------------------------------------------------------------------
echo "${CYAN}***************************************************************************************************************************${NC}"
echo "${CYAN}---------------------------------------------------------------------------------------------------------------------------${NC}"
echo " ${PURPLE}${healthy} Pre-Install Checks${NC}"
echo "${CYAN}---------------------------------------------------------------------------------------------------------------------------${NC}"

        checkHelmExecutable

        checkCloudctlExecutable

        checkOpenshiftReachable

        checkKubeconfigIsSet

        checkStorageClassExists

        checkDefaultStorageDefined

        checkRegistryCredentials

        checkHelmChartInstalled $HELM_RELEASE_NAME

        #checkClusterServiceBroker

echo "${CYAN}---------------------------------------------------------------------------------------------------------------------------${NC}"
echo "${CYAN}***************************************************************************************************************************${NC}"
echo "  "
echo "  "
echo "  "
echo "  "





# ---------------------------------------------------------------------------------------------------------------------------------------------------"
# ---------------------------------------------------------------------------------------------------------------------------------------------------"
# Define some Stuff
# ---------------------------------------------------------------------------------------------------------------------------------------------------"
# ---------------------------------------------------------------------------------------------------------------------------------------------------"
echo "${CYAN}***************************************************************************************************************************${NC}"
echo "${CYAN}---------------------------------------------------------------------------------------------------------------------------${NC}"
echo " ${PURPLE}${memo} Define some Stuff${NC}"
echo "${CYAN}---------------------------------------------------------------------------------------------------------------------------${NC}"

        getInstallPath

echo "${CYAN}---------------------------------------------------------------------------------------------------------------------------${NC}"
echo "${CYAN}***************************************************************************************************************************${NC}"
echo "  "
echo "  "
echo "  "
echo "  "





# ------------------------------------------------------------------------------------------------------------------------------------------------------------------------
# ------------------------------------------------------------------------------------------------------------------------------------------------------------------------
# CONFIG SUMMARY
# ------------------------------------------------------------------------------------------------------------------------------------------------------------------------
# ------------------------------------------------------------------------------------------------------------------------------------------------------------------------
echo "${GREEN}***************************************************************************************************************************${NC}"
echo "${GREEN}---------------------------------------------------------------------------------------------------------------------------${NC}"
echo " ${GREEN}${healthy} CAM will be installed in Cluster ${ORANGE}'$CLUSTER_NAME'${NC}"
echo "${GREEN}---------------------------------------------------------------------------------------------------------------------------${NC}"
echo " ${PURPLE} ${magnifying} Your configuration${NC}"
echo "    ---------------------------------------------------------------------------------------------------------------------"
echo "    ${GREEN}CLUSTER :${NC}             $CLUSTER_NAME"
echo "    ${GREEN}REGISTRY TOKEN:${NC}       $ENTITLED_REGISTRY_KEY"
echo "    ---------------------------------------------------------------------------------------------------------------------"
echo "    ${GREEN}MCM Server:${NC}           $MCM_SERVER"
echo "    ${GREEN}MCM User Name:${NC}        $MCM_USER"
echo "    ${GREEN}MCM User Password:${NC}    ************"
echo "    ---------------------------------------------------------------------------------------------------------------------"
echo "    ${GREEN}STORAGE CLASS BLOCK:${NC}  $STORAGE_CLASS_BLOCK"
echo "    ${GREEN}STORAGE CLASS FILE:${NC}   $STORAGE_CLASS_FILE"
echo "    ---------------------------------------------------------------------------------------------------------------------"
echo "    ${GREEN}INSTALL PATH:${NC}         $INSTALL_PATH"
echo "${GREEN}---------------------------------------------------------------------------------------------------------------------------${NC}"
echo "${GREEN}***************************************************************************************************************************${NC}"
echo "  "
echo "  "
echo "  "
echo "  "




echo "${ORANGE}---------------------------------------------------------------------------------------------------------------------------${NC}"
echo "${ORANGE}---------------------------------------------------------------------------------------------------------------------------${NC}"
echo "${RED}${whitequestion}Continue Installation with these Parameters? [y,N]${NC}"
echo "${ORANGE}---------------------------------------------------------------------------------------------------------------------------${NC}"
echo "${ORANGE}---------------------------------------------------------------------------------------------------------------------------${NC}"
        read -p "[y,N]" DO_COMM
        if [[ $DO_COMM == "y" ||  $DO_COMM == "Y" ]]; then
          echo "${GREEN}Continue...${NC}"
        else
          echo "${RED}${cross} Installation Aborted${NC}"
          exit 2
        fi
echo "  "
echo "  "
echo "  "
echo "  "


# ------------------------------------------------------------------------------------------------------------------------------------------------------------------------
# ------------------------------------------------------------------------------------------------------------------------------------------------------------------------
# PREREQUISITES
# ------------------------------------------------------------------------------------------------------------------------------------------------------------------------
# ------------------------------------------------------------------------------------------------------------------------------------------------------------------------
echo "${CYAN}***************************************************************************************************************************${NC}"
echo "${CYAN}---------------------------------------------------------------------------------------------------------------------------${NC}"
echo " ${CYAN}${wrench} Running Prerequisites${NC}"
echo "${CYAN}---------------------------------------------------------------------------------------------------------------------------${NC}"

        echo "---------------------------------------------------------------------------------------------------------------------------"
        echo " ${wrench} Create ${CYAN}Config Directory{NC}"
        #rm -r $INSTALL_PATH/* 
        mkdir -p $INSTALL_PATH 
        cd $INSTALL_PATH
        echo "    ${GREEN}  OK${NC}"
        echo "  "


        echo "----------------------------------------------------------------------------------------------------------------------------------------------------"
        echo " ${wrench} Create ${CYAN}Policies${NC}"
        POLICY_USCC=$(oc adm policy add-scc-to-user ibm-anyuid-hostpath-scc system:serviceaccount:services:default 2>&1)
        POLICY_GSCC=$(oc adm policy add-scc-to-group privileged system:serviceaccounts:services 2>&1)
        echo "    ${GREEN}  OK${NC}"
        echo "  "

        echo "----------------------------------------------------------------------------------------------------------------------------------------------------"
        echo " ${wrench} Create ${CYAN}Secret${NC}"
        kubectl delete secret -n services camsecret
        kubectl create secret docker-registry camsecret --docker-username="$ENTITLED_REGISTRY_USER" --docker-password="$ENTITLED_REGISTRY_KEY" --docker-email="test@us.ibm.com" --docker-server="cp.icr.io" -n services
        echo "    ${GREEN}  OK${NC}"
        echo "  "
        
        echo "----------------------------------------------------------------------------------------------------------------------------------------------------"
        echo " ${wrench} Create ${CYAN}Service Account${NC}"
        kubectl patch serviceaccount default -p '{"imagePullSecrets": [{"name": "camsecret"}]}' -n services
        echo "    ${GREEN}  OK${NC}"
        echo "  "
        
echo "${CYAN}---------------------------------------------------------------------------------------------------------------------------${NC}"
echo "${CYAN}***************************************************************************************************************************${NC}"
echo "  "
echo "  "
echo "  "
echo "  "



# ------------------------------------------------------------------------------------------------------------------------------------------------------------------------
# ------------------------------------------------------------------------------------------------------------------------------------------------------------------------
# SERVICE ID
# ------------------------------------------------------------------------------------------------------------------------------------------------------------------------
# ------------------------------------------------------------------------------------------------------------------------------------------------------------------------
echo "${CYAN}***************************************************************************************************************************${NC}"
echo "${CYAN}---------------------------------------------------------------------------------------------------------------------------${NC}"
echo " ${CYAN}${wrench} Create Service ID${NC}"
echo "${CYAN}---------------------------------------------------------------------------------------------------------------------------${NC}"

        TOKEN_EXISTS=$(ls 2>&1)

        if [[ $TOKEN_EXISTS =~ "token.txt" ]];
        then
          echo "  ${ORANGE}WARNING${NC}: TOKEN already exists"
          read -p "  Delete and recreate? [y,N]" DO_COMM
          if [[ $DO_COMM == "y" ||  $DO_COMM == "Y" ]]; then
            rm token.txt
            createToken
          fi
        else 
          echo "    ${GREEN}OK - Creating TOKEN${NC}"
          createToken
        fi

        export SERVICE_TOKEN=$(cat token.txt | tail -1 | awk '{ print $3 }')


echo "----------------------------------------------------------------------------------------------------------------------------------------------------"
echo " Using Service ID TOKEN:"
echo "    "${RED}$SERVICE_TOKEN${NC}
echo "${CYAN}---------------------------------------------------------------------------------------------------------------------------${NC}"
echo "${CYAN}***************************************************************************************************************************${NC}"
echo "  "
echo "  "
echo "  "
echo "  "





# ------------------------------------------------------------------------------------------------------------------------------------------------------------------------
# ------------------------------------------------------------------------------------------------------------------------------------------------------------------------
# HELM CHART
# ------------------------------------------------------------------------------------------------------------------------------------------------------------------------
# ------------------------------------------------------------------------------------------------------------------------------------------------------------------------
echo "${CYAN}***************************************************************************************************************************${NC}"
echo "${CYAN}---------------------------------------------------------------------------------------------------------------------------${NC}"
echo " ${CYAN}${wrench} Helm Chart${NC}"
echo "${CYAN}---------------------------------------------------------------------------------------------------------------------------${NC}"

        CHART_EXISTS=$(ls 2>&1)

        if [[ $CHART_EXISTS =~ $CAM_VERSION ]];
        then
          echo "    ${GREEN}OK - Chart already Downloaded${NC}"
        else 
          echo "    ${GREEN}Downloading Chart${NC}"
          LOGIN_OK=$(cloudctl login -a ${MCM_SERVER} --skip-ssl-validation -u ${MCM_USER} -p ${MCM_PWD} -n kube-system)
          if [[ $LOGIN_OK =~ "Error response from server" ]];
          then
                echo "    ${RED}ERROR${NC}: Could not login to MCM Hub on Cluster '$CLUSTER_NAME'. Aborting."
                exit 2
          else
            $HELM_BIN init --client-only
            $HELM_BIN repo add ibm-stable https://raw.githubusercontent.com/IBM/charts/master/repo/stable/
            $HELM_BIN repo update
            $HELM_BIN fetch ibm-stable/ibm-cam --version $CAM_VERSION
          fi
        fi

echo "${CYAN}---------------------------------------------------------------------------------------------------------------------------${NC}"
echo "${CYAN}***************************************************************************************************************************${NC}"
echo "  "
echo "  "
echo "  "
echo "  "







# ------------------------------------------------------------------------------------------------------------------------------------------------------------------------
# ------------------------------------------------------------------------------------------------------------------------------------------------------------------------
# INSTALL
# ------------------------------------------------------------------------------------------------------------------------------------------------------------------------
# ------------------------------------------------------------------------------------------------------------------------------------------------------------------------
echo "${ORANGE}---------------------------------------------------------------------------------------------------------------------------${NC}"
echo "${ORANGE}---------------------------------------------------------------------------------------------------------------------------${NC}"
echo " ${RED}${whitequestion} Do you want to install CAM into Cluster '$CLUSTER_NAME'?${NC}"
echo ""
echo "${ORANGE}---------------------------------------------------------------------------------------------------------------------------${NC}"
echo "${ORANGE}---------------------------------------------------------------------------------------------------------------------------${NC}"

        read -p "Install? [y,N]" DO_COMM
        if [[ $DO_COMM == "y" ||  $DO_COMM == "Y" ]]; then


          read -p "Install with Persistence for all (otherwise only for MongoDB)? [y,N]" DO_COMM
          if [[ $DO_COMM == "y" ||  $DO_COMM == "Y" ]]; then
          $HELM_BIN install --name $HELM_RELEASE_NAME ibm-cam-$CAM_VERSION.tgz --timeout=9999 --wait \
            --namespace services  \
            --set global.image.secretName=camsecret  \
            --set arch=amd64  \
            --set global.iam.deployApiKey=$SERVICE_TOKEN  \
            --set icp.port=443  \
            --set global.audit=false \
            --set camMongoPV.persistence.storageClassName=$STORAGE_CLASS_BLOCK \
            --set camMongoPV.persistence.enabled=true \
            --set camMongoPV.persistence.accessMode=ReadWriteOnce \
            --set camMongoPV.persistence.useDynamicProvisioning=true \
            --set camLogsPV.persistence.useDynamicProvisioning=true \
            --set camLogsPV.persistence.storageClassName=$STORAGE_CLASS_FILE \
            --set camLogsPV.persistence.accessMode=ReadWriteMany \
            --set camTerraformPV.persistence.useDynamicProvisioning=true \
            --set camTerraformPV.persistence.storageClassName=$STORAGE_CLASS_FILE \
            --set camTerraformPV.persistence.accessMode=ReadWriteMany \
            --set camBPDAppDataPV.persistence.useDynamicProvisioning=true \
            --set camBPDAppDataPV.persistence.storageClassName=$STORAGE_CLASS_FILE \
            --set camBPDAppDataPV.persistence.accessMode=ReadWriteMany \
            $HELM_TLS
          else
            $HELM_BIN install --name $HELM_RELEASE_NAME ibm-cam-$CAM_VERSION.tgz  --timeout=9999 --wait \
            --namespace services  \
            --set global.image.secretName=camsecret  \
            --set arch=amd64  \
            --set global.iam.deployApiKey=$SERVICE_TOKEN  \
            --set icp.port=443  \
            --set global.audit=false \
            --set camMongoPV.persistence.storageClassName=$STORAGE_CLASS_BLOCK \
            --set camMongoPV.persistence.enabled=true \
            --set camMongoPV.persistence.accessMode=ReadWriteOnce \
            --set camMongoPV.persistence.useDynamicProvisioning=true \
            --set camLogsPV.persistence.enabled=false \
            --set camBPDAppDataPV.persistence.enabled=false \
            --set camTerraformPV.persistence.enabled=false \
            $HELM_TLS
          fi



          echo ""
          echo ""
          echo ""
          echo ""
          echo ""
          echo ""
          echo "${ORANGE}----------------------------------------------------------------------------------------------------------------------------------------------------${NC}"
          echo "${ORANGE}----------------------------------------------------------------------------------------------------------------------------------------------------${NC}"
          echo " ${RED}${exclamation} Post Install:${NC} Register CAM into MCM UI in '$CLUSTER_NAME'?"
          echo "${ORANGE}----------------------------------------------------------------------------------------------------------------------------------------------------${NC}"
          echo "${ORANGE}----------------------------------------------------------------------------------------------------------------------------------------------------${NC}"
          echo " Please run"
          echo "  ${ORANGE}./tools/navigation/automation-navigation-updates.sh -a services${NC}"
          echo ""
          echo ""
        else
          echo "${RED}${cross} Installation Aborted${NC}"
          exit 2

        fi



echo "${GREEN}----------------------------------------------------------------------------------------------------------------------------------------------------${NC}"
echo "${GREEN}----------------------------------------------------------------------------------------------------------------------------------------------------${NC}"
echo " ${GREEN}${healthy} CAM Installation.... DONE${NC}"
echo "${GREEN}----------------------------------------------------------------------------------------------------------------------------------------------------${NC}"
echo "${GREEN}----------------------------------------------------------------------------------------------------------------------------------------------------${NC}"
echo " ${GREEN} If you get a privacy error in Chrome you can type "thisisunsafe" (without any visual feedback) to load the page${NC}"
echo "${GREEN}----------------------------------------------------------------------------------------------------------------------------------------------------${NC}"
echo "${GREEN}----------------------------------------------------------------------------------------------------------------------------------------------------${NC}"
echo " ${GREEN}${explosion} To remove release: $HELM_BIN delete $HELM_RELEASE_NAME --purge  --timeout=9999 --wait $HELM_TLS${NC}"
echo "${GREEN}***************************************************************************************************************************************************${NC}"
echo "${GREEN}***************************************************************************************************************************************************${NC}"


exit 2


kubectl get svc -n kube-system tiller-deploy

--host=10.111.221.14:443

cloudctl login -a https://icp-console.cp4mcm001-a376efc1170b9b8ace6422196c51e491-0000.us-south.containers.appdomain.cloud/ --skip-ssl-validation -u admin -p P4ssw0rd! -n kube-system


helm2 install --name cam ibm-cam-4.2.0.tgz \
--namespace services  \
--set global.image.secretName=camsecret  \
--set arch=amd64  \
--set global.iam.deployApiKey=8ZdE0lwGi-3zDCeu1lAhTdpxHXD6rwaUn4v__pd1-uRy  \
--set icp.port=443  \
--set global.audit=false \
--set camMongoPV.persistence.storageClassName=ibmc-block-gold \
--set camMongoPV.persistence.enabled=true \
--set camMongoPV.persistence.accessMode=ReadWriteOnce \
--set camMongoPV.persistence.useDynamicProvisioning=true \
--set camLogsPV.persistence.enabled=false \
--set camBPDAppDataPV.persistence.enabled=false \
--set camTerraformPV.persistence.enabled=false \
--tls

kubectl patch -n openshift-service-catalog-apiserver servicecatalogapiserver cluster --type=json -p '[{"op":"replace","path":"/spec/managementState","value":"Removed"}]'
kubectl patch -n openshift-service-catalog-controller-manager servicecatalogcontrollermanager cluster --type=json -p '[{"op":"replace","path":"/spec/managementState","value":"Removed"}]'
kubectl patch -n openshift-service-catalog-apiserver servicecatalogapiserver cluster --type=json -p '[{"op":"replace","path":"/spec/managementState","value":"Managed"}]'
kubectl patch -n openshift-service-catalog-controller-manager servicecatalogcontrollermanager cluster --type=json -p '[{"op":"replace","path":"/spec/managementState","value":"Managed"}]'