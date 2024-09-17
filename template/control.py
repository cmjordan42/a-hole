#!/bin/python3

import sys, subprocess, argparse, os

def main(argv):
    parser = argparse.ArgumentParser()
    parser.add_argument('subsystem', nargs=1)
    parser.add_argument('operation', nargs=1)
    parser.add_argument('arguments', nargs=argparse.REMAINDER)
    cmd = parser.parse_args()

    pwd = os.path.dirname(os.path.realpath(__file__))
    subsystem = cmd.subsystem[0]
    op = cmd.operation[0]
    args = cmd.arguments

    dockerexec = [ 'docker', 'exec', '-it' ]
    command = []

    dc_location = pwd + '/docker-compose.yml'
    if subsystem == '-':
        if op == 'up':
            command += [ 'docker-compose', '--file', dc_location, 'up', '-d' ]
            command += args
        elif op == 'down':
            command += [ 'docker-compose', '--file', dc_location, 'down' ]
            command += args
    elif op in ('/', '?', '-'):
        if op == '/':
            command += dockerexec + [ subsystem ] + [ '/bin/bash' ]
        elif op == '?':
            command += [ 'docker', 'logs', subsystem ]
        elif op == '-':
            command += dockerexec + [ subsystem ] + args
    else:
        command += dockerexec + [ subsystem ] 
        if subsystem == 'certbot':
            print ('no specific daemon')
        elif subsystem == 'ddns':
            print ('no specific commands')
        elif subsystem == 'pihole':
            if op == 'password':
                command += [ 'pihole', '-a', '-p' ] + args
            elif op == 'status':
                command += [ 'pihole', 'status' ]
        elif subsystem in ('dnsproxy'):
            print ('no specific commands')
        elif subsystem in ('unbound'):
            print ('no specific commands')
        elif subsystem == 'wg':
            if op == 'qr':
                command += [ '/app/show-peer' ] + args
            elif op == 'config':
                command += [ 'cat', '/config/peer_' + args[0] + '/peer_' + args[0] + '.conf']
            elif op == 'status':
                command += [ 'wg', 'show', 'all' ]

    # print(*command)
    if command != []:
        result = subprocess.run(command, capture_output=False, text=True)

if __name__ == '__main__':
    main(sys.argv[1:])