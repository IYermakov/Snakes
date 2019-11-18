docker run -d -p 8080:8080 -p 2222:22 --name my-docker-container my-docker-image
sleep 5s
curl localhost:8080
