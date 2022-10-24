#Baseimage
FROM python:3.8-slim-buster

# copy the requirements file used for dependencies
WORKDIR /app

# copy the requirements file used for dependencies
COPY requirements.txt requirements.txt

# Install any needed packages specified in requirements.txt
RUN pip3 install -r requirements.txt

COPY . .

# Run the web service on container startup. Here we use the gunicorn
# webserver, with one worker process and 8 threads.
# For environments with multiple CPU cores, increase the number of workers
# to be equal to the cores available.
CMD [ "python3", "main.py"]