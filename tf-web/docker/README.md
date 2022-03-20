# docker-phpapp

**How to Dockerize an Php Application**

I created a Docker image that php hello-world application.

 **Docker compose** file to run a Docker container using the Docker image we just created.

Inside the docker-compose.yml file, we have the version, services, app, build, port and volumes tag. The version tag is used to define the Compose file format.

 For our application, we only have one service called app. The build command will build our Docker image using the Dockerfile we created earlier.

 The ports tag is used to define container ports. 

 The `docker compose up` command will start and run the entire app.
