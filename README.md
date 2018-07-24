**Openvas Docker container**

This container is based on Centos 7 for FIPS-140-2 compliance. It is a self contained Openvas Scanner with web console on port 443.  


**Launch**

	docker run -d -p 443:443 --name openvas atomicorp/openvas


	https://<IP>/
	Default login / password: admin / admin

**Launch with a Volume**

	docker volume create openvas

	docker run -d -p 443:443 -v openvas:/var/lib/openvas/mgr --name openvas atomicorp/openvas

**Set Admin Password**

	docker run -d -p 443:443 -e OV_PASSWORD=iliketurtles --name openvas atomicorp/openvas

**Update NVT data**

	Note: This process may take take some time. 

	docker run -d -p 443:443 -e OV_UPDATE=yes --name openvas atomicorp/openvas


**Attach to running**

	docker exec -it openvas bash


**Thanks**

	Michael Meyer @Greenbone

	Jan-Oliver Wagner @Greenbone

	Everyone at Greenbone that made this project possible

	The Arachni Project 

	Openvas Docker creators used as a reference: Mike Splain, William Collani, Serge Katzmann, and Daniel Popescu
