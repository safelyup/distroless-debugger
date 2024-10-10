# distroless-debugger
2 possible solutions for enabling access to application processes in distroless containers for debugging purposes.

The demo setup contains one distroless Java application, the "debugger" image, and a Kubernetes manifest.

## Blog Post

For more info see the [Blog Post](https://safelyup.net/debugging-distroless-kubernetes-containers-74cfde06b196).

## Local Deployment - Minikube

Minikube must already be deployed locally.

Build the demo application and debugger images:
```
cd ./demo-app
docker build --no-cache -t demo-app:v1 .
cd ../debugger
docker build --no-cache -t debugger:v1 .
cd ../
```

And push the images to a container registry. If you are using Minikube locally, you can load the images to its local cache:
```
minikube image load demo-app:v1
minikube image load debugger:v1
```

## Use as Ephemeral Container (No Pod Restart)
To immediately get access and debug a running `distroless` container; get heapdump and download the file to your local box, without restarting the Pod.

To be able to run `kubectl debug` we need to have write access to `pods/ephemeralcontainers` K8s API.

```
$ kubectl debug -it -c debugger --target=<MAIN-CONTAINER-NAME> --image=docker.io/library/debugger:v1 <POD-NAME>
Targeting container "demo".
If you don't see a command prompt, try pressing enter.
/ # ps
PID  USER     TIME  COMMAND
  1  root     0:00 /usr/bin/java -jar main.jar
  31 root     0:00 sh /.debugger.sh
```

The `--target` option shares the debugger container's PID namespace with the main container, which is necessary to access the running main `java` process.

The default CMD for the image is the sh script `/run.sh` which makes debugging the main container possible, and copies some useful (optional) tools into the main container's filesystem, and starts an `sh` session on the debugger container running on FS of the main container.

Once you run `exit` in the debugger sh session, it will die and you can't connect to it again. Run `kubectl debug` again with a different name for the ephemeral container e.g. `-c debugger2`, to deploy a new one.

## Use as Sidecar Container (Requires Pod Restart)
Without having `kubectl debug` access, we still can run the debugger as a normal sidecar container alongside the main container, by updating the Pod or Deployment manifest, which is going to trigger a restart.

```
...
  spec:
    shareProcessNamespace: true
    containers:
      - name: debugger
        image: docker.io/library/debugger:v0
        command: ["sh"]
        args: ["-c", "sleep infinity"]
      - name: main
      ...
```

Add the debugger as a new container, but override its default CMD, so it doesn't immediately exit. We need it to stay up for our later use.
`shareProcessNamespace` config is also necessary to access the PID namespace of other containers in the Pod from debugger.

Once it is deployed, we can connect to the debugger locally, by executing `/run.sh` every time.

```
$ kubectl exec -c debugger -it <POD-NAME> -- /run.sh
/ # ps
PID   USER  TIME  COMMAND
   1 65535  0:00 /pause
  30 root   0:00 sleep infinity
  36 root   0:07 /usr/bin/java -jar main.jar
 105 root   0:00 sh /.debugger.sh
```

As you can see, `java` process in the main container is accessible.
