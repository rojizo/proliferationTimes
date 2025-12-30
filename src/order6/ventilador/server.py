#! /usr/bin/env python3

# TODO: add error handling

# Some internal variables
__author__ = 'Alvaro Lozano Rojo'

import zmq
import zmq.auth
from zmq.auth.thread import ThreadAuthenticator
import uuid
import time
import pickle
import glob
import os
import shutil
import sys
import random

# User-defined modules
import errors
import request_types

# Global variables (arg!)
if getattr(sys, 'frozen', False):
    # The application is frozen
    BASEPATH = os.path.dirname(sys.executable)
else:
    # The application is not frozen
    # Change this bit to match where you store your data files:
    BASEPATH = os.path.dirname(__file__)

OUTPUT = os.path.join(BASEPATH, 'global_output.txt')

IDs = [17317767192, 17585156104, 17585156098, 17585676292, 17584629770, 17584624656, 17585679384]
degsBin = [145,142,137,131,133,125, 119]

xx = []
y = []
for k in range(10, 100):
    xx.append((k, 100))
    y.append((k, 10))
xx.extend(y)
del y
rvals = xx
del xx
rvals.append((10, 1))

Tasks = [(ID, tipo, deg, r, fixation) for ID, deg in zip(IDs, degsBin) for tipo in ["ber", "bin"] for r in rvals for fixation in [False, True]]

# Delete already done tasks
with open(OUTPUT, "rt") as infile:
    DONE = []
    for line in infile.readlines():
        id, tipo, deg, r1, r2, fixation, _, _ = line.split()
        id = int(id[:-1])
        tipo = tipo[:-1]
        deg = int(deg[:-1])
        r = (int(r1[1:-1]), int(r2[:-2]))
        fixation = (fixation == "True,")
        DONE.append((id, tipo, deg, r, fixation))
Tasks = list(set(Tasks) - set(DONE))

random.shuffle(Tasks)


#####################################################
##
## Return new task... if there is any
##
#####################################################
def new_task(res):
    """
    Returns a new task to send. The res variable is the request
    """

    # This will be the returned task
    task = {'type': ''}
    # We will populate the dict so the client can use it

    if len(Tasks):
        task['id'], task['process'], task['deg'], task['r'], task['fixation'] = Tasks.pop()

    else:  # no task
        print("There is no tasks to send")
        task['type'] = request_types.ERROR
        task.update(errors.ERROR_NO_TASK)
        return task

    # Someone needs work
    print(f"Task '{task['id']}, {task['process']}, {task['deg']}, {task['r']}, '{task['fixation']}' sent")

    return task


#####################################################
##
## Process an answer
##
#####################################################
def process_answer(res):
    """
    Process the answer.
    """

    # Ok, the task was assigned and someone is sending the answer
    print(f"Task '{res['id']}, {res['process']}, {res['deg']}, {res['r']}, {res['fixation']}' answered")

    # Save the answer
    with open(OUTPUT, "at") as outfile:
        print(f"{res['id']}, {res['process']}, {res['deg']}, {res['r']}, {res['fixation']}, {res['times']}", file=outfile)

    # Return
    return {'type': request_types.OK}


######################################################
##
## Entry point
##
#####################################################
def main():
    # Folders and files for certificates
    CertificatesFolder = os.path.join(BASEPATH, 'certificates')
    ServerPublicKeyFile = os.path.join(CertificatesFolder, 'server.key')
    ServerPrivateKeyFile = os.path.join(CertificatesFolder, 'server.key_secret')

    # Check if there are keys
    if not (os.path.isfile(ServerPublicKeyFile) and
            os.path.isfile(ServerPrivateKeyFile)):
        print("Server's public key is missing!! Clients will have real problems")
        return None
    # Load the keys
    ServerPublicKey, ServerPrivateKey = zmq.auth.load_certificate(ServerPrivateKeyFile)

    # Initializing server
    print('Setting up server... ', end='')
    context = zmq.Context()
    # Start an authenticator for this context.
    auth = ThreadAuthenticator(context)
    auth.start()
    # Tell the authenticator how to handle CURVE requests
    auth.configure_curve(domain='*', location=zmq.auth.CURVE_ALLOW_ANY)
    # Create the socket
    socket = context.socket(zmq.REP)
    # Setup the keys
    socket.curve_secretkey = ServerPrivateKey
    socket.curve_publickey = ServerPublicKey
    socket.curve_server = True  # must come before bind
    # Accept all connections on tcp 5555 port
    socket.bind("tcp://*:5555")

    # Server running
    print('Done!')

    print(f"There are {len(Tasks)} remaining!")


    # Start parsing requests... util the end of days
    while True:
        # Wait for a request... as a Python object...
        res = socket.recv_pyobj()
        print('Incoming message... ', end='')

        # I've one... let's see what it is
        # First of all, it should be a dict object
        if type(res) == dict:
            req_type = res.get('type')

            if req_type == request_types.ASK_FOR_WORK:
                # Someone needs work
                print('Someone needs work... ', end='')

                # Send the task back
                socket.send_pyobj(new_task(res))

            elif req_type == request_types.RETURN_WORK:
                # Hey! Someone sent an answer! Lets check if it is overdue or not and save it accordingly
                print('Hey! Someone sent an answer...')
                # Process the answer
                socket.send_pyobj(process_answer(res))

            else:
                # I don't known what have they sent to me...
                # I'm going just answer 'ERROR' and some info in a JSON
                print("Unknown message type... ignoring it.")
                res = {'type': request_types.ERROR}
                res.update(error.ERROR_UNKNOWN_REQUEST)
                socket.send_pyobj(res)

        else:
            # I don't known what have they sent to me...
            # I'm going just answer 'ERROR' and some info in a JSON
            print("Malformed message... ignoring it.")
            res = {'type': request_types.ERROR}
            res.update(error.ERROR_NONDICT_REQUEST)
            socket.send_pyobj(red)

    # Destroy context and end... this never happends...
    auth.stop()
    context.destroy()
    quit()


if __name__ == '__main__':
    main()
