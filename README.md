Openvas Docker container

Launch:

	docker run -d -p 443:443 --name openvas <image>

Launch with a Volume:

	docker volume create openvas

	docker run -d -p 443:443 -v openvas:/var/lib/openvas/mgr --name openvas <image>

Set Admin Password

	docker run -d -p 443:443 -e OV_PASSWORD=somepassword --name openvas <image>


Attach to running

	docker exec -it openvas bash


Thanks

	Jan-Oliver Wagner @Greenbone
	
	Michael Meyer @Greenbone

	Everyone at Greenbone that made this project possible

	The Arachni Project 

	Openvas Docker creators used as a reference: Mike Splain, William Collani, Serge Katzmann, and Daniel Popescu
