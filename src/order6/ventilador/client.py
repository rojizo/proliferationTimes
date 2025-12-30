#! /usr/bin/env python3

"""
Bigdata & Distributed Computation Client
"""

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
import tarfile
import sys
import proliferation as pp
import networkx as nx
import numpy as np

# User-defined modules
import errors
import request_types

def id2el(Id):
    """Constructs the graph associated to the number Id.
    """
    el = []

    Id = int(Id)

    mask = 1
    u = 0
    v = 1
    while u < 10:
        if (Id & mask):
            el.append((u,v))
    
        mask = (mask << 1)
        v += 1
    
        if v > 10:
            u += 1
            v = u+1
    return el
id2G  = lambda Id : nx.from_edgelist(id2el(np.uint64(Id)))


######################################################
##
## Useful print function
##
#####################################################
def info(*args, **kwargs):
    print(*args, file=sys.stdout, **kwargs)
    sys.stdout.flush()


######################################################
##
## Entry point
##
#####################################################
def main():
    try:
        # Get the server IP from command line
        if len(sys.argv) > 1:
            SERVER_IP = sys.argv[1]
        else:
            SERVER_IP = '127.0.0.1'
        
        # Just in case I'm frozen
        if getattr(sys, 'frozen', False):
            # The application is frozen
            BASEPATH = os.path.dirname(sys.executable)
        else:
            # The application is not frozen
            # Change this bit to match where you store your data files:
            BASEPATH = os.path.dirname(__file__)
        
        # Folders and files for certificates
        CertificatesFolder   = os.path.join(BASEPATH, 'certificates')
        ServerPublicKeyFile  = os.path.join(CertificatesFolder, 'server.key')
        ClientPublicKeyFile  = os.path.join(CertificatesFolder, 'client.key')
        ClientPrivateKeyFile = os.path.join(CertificatesFolder, 'client.key_secret')
        
        # Check if the public keys exists
        if not os.path.isfile(ServerPublicKeyFile):
            info("Server's public key is missing!!")
            return None
        # it exists... load it
        ServerPublicKey, _ = zmq.auth.load_certificate(ServerPublicKeyFile)
        
        #Now, my own key
        if not (os.path.isfile(ClientPrivateKeyFile) and 
                os.path.isfile(ClientPublicKeyFile )      ):
            # Missing keys, generate them
            for d in [ClientPrivateKeyFile, ClientPublicKeyFile]:
                if os.path.exists(d):
                    #shutil.rmtree(d)
                    os.system('rm -r '+d)
            ClientPublicKeyFile, ClientPrivateKeyFile = zmq.auth.create_certificates(CertificatesFolder, "client")
        # Load client's keys
        ClientPublicKey, ClientPrivateKey = zmq.auth.load_certificate(ClientPrivateKeyFile)
        
        # Setup the connection with authentication
        context = zmq.Context()
        # Start an authenticator for this context.
        auth = ThreadAuthenticator(context)
        auth.start()
        # Only allow connections to/from server
        auth.allow(SERVER_IP) 
        # Tell the authenticator how to handle CURVE requests
        auth.configure_curve(domain='*', location=zmq.auth.CURVE_ALLOW_ANY)
    
        # Socket to talk to server
        socket = context.socket(zmq.REQ)
        # Set my keys on the socket
        socket.curve_secretkey = ClientPrivateKey
        socket.curve_publickey = ClientPublicKey
        # The client must know the server's public key to make a CURVE connection.
        socket.curve_serverkey = ServerPublicKey
    
        #Set the reconnection and keep alive settings... finger crossed
        socket.TCP_KEEPALIVE       = 1 #Keep things alive
        socket.TCP_KEEPALIVE_IDLE  = 1
        socket.TCP_KEEPALIVE_CNT   = 1
        
        # Connect to server
        info("Connecting to {}...".format(SERVER_IP), end=' ')
        socket.connect("tcp://{}:5555".format(SERVER_IP))
        info("Done!")

        computationCache = {"ber": {}, "bin": {}}
    
        # Work forever... well, at least until there is no work
        while True:
            # Ask for some work
            info("Asking to {} for some work".format(SERVER_IP), end=" ")
            socket.send_pyobj({'type': request_types.ASK_FOR_WORK})

            # Get the reply.
            res = socket.recv_pyobj()
            
            #Process it..
            if res['type'] == request_types.ERROR: 
                # It is an error... UOPS
                info("\n{:=^70}".format("Error "+str(res['err_id'])))
                info(res['err_description'])
                break
                
            else:
                # It is OK... so copy everything in place and go... 
                # in the next step if will be processed
                info(f"Task for {res['id']} w/ process {res['process']}, deg {res['deg']} and r {res['r']} received. Working")

                ID = res['id']
                process = res['process']
                deg = res['deg']
                r = res['r']
                fixation = res["fixation"]

                if ID in computationCache[process]:
                    K = computationCache[process][ID]
                else:
                    G = id2G(ID)
                    if process == "bin":
                        K = pp.timesOnCriticalityBinomial(G)
                    else:
                        K = pp.timesOnCriticalityBernoulli(G)
                    computationCache[process][ID] = K

                if process == "bin":
                    arguments = (*r, deg)
                else:
                    arguments = r

                if fixation:
                    times = K.critical_fixation_time(*arguments)
                else:
                    times = K.critical_absorption_time(*arguments)
                del arguments # JIC

                # Send the result back
                info("Sending results back to {}".format(SERVER_IP), end=' ')
                socket.send_pyobj({
                    'type'   : request_types.RETURN_WORK,
                    'id'     : ID,
                    'process': process,
                    'deg'    : deg,
                    "r"      : r,
                    "fixation": fixation,
                    "times"   : times
                })
    
                # Get the reply.
                res = socket.recv_pyobj()
                info("done!")
    
    except Exception as e:
        info("\n\n\nSomething bad happened\n\n\n")
        info(repr(e))

    auth.stop()
    context.destroy()

if __name__ == '__main__':
    main()
    info("\n\nBye\n\n")
