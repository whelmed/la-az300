# Virtual Networks (VNet) for Solutions Architects

## Use Cases
* Allows certain Azure resources to communicate with each other and with the internet 
    * Compute
        * Virtual machines: Linux or Windows
        * Virtual machine scale sets
        * Azure Batch
    * Network	
        * Application Gateway - WAF
        * VPN Gateway
        * Azure Firewall 
        * Network Virtual Applicances
    * Data	
        * RedisCache
        * Azure SQL Database Managed Instance
    * Analytics	
        * Azure HDInsight
        * Azure Databricks
    * Identity
        * Azure Active Directory Domain Services
    * Containers	
        * Azure Kubernetes Service (AKS)
        * Azure Container Instance (ACI)
        * Azure Container Service Engine with Azure Virtual Network CNI plug-in
    * Web	
        * API Management
        * App Service Environment

* Allow resources inside of a VNet to interact with select services via Service Endpoints.
    
    * Azure Storage: GA in all regions. 
    * Azure SQL Database: GA in all regions. 
    * Azure SQL Data Warehouse: GA in all regions. 
    * Azure Database for PostgreSQL server: GA in all regions supporting database service.
    * Azure Database for MySQL server: GA in all regions supporting database service.
    * Azure Cosmos DB: GA in all public cloud regions. 
    * Azure Key Vault: GA in all public cloud regions. 


## VNet Resources
* VNet
    * Subnet
        * NSG (Network Security Group)
        * Route Table
            * UDR (User Defined Route)
    * Network Interface
        * IP Address
        * NSG (Network Security Group)
    * Peering



## Features
* Security Groups
    * Filter traffic to and from Azure resources. Create security rules that can either allow or deny traffic.
* Routing
    * Azure networks provide default system routes. Those routes can be overridden with custom-user defined routes. User defined routes allow traffic to be redirected. This functionality facilitates routing traffic through virtual appliances such as a security appliance.
* Service Endpoints
    * Service endpoints allow a direct connection between a supported service and resources inside a VNet. This can make the connection more secure by preventing service access from the internet.
* Peering
    * VNets are isolated from each other. Peering allows VNets to be connected such that resources inside each can communicate. Traffic on a peered network travels via Microsoft's backbone infrastructure, rather than over the public internet. Peering is possible both inside a single region, and cross-region.
