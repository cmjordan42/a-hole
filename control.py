#!/bin/python3

import sys, subprocess, argparse

def main(argv):
    containers = [ 'noip', 'certbot', 'pihole', 'wg', 'unbound', 'proxy' ]

    parser = argparse.ArgumentParser()
    parser.add_argument('subsystem', nargs=1, choices=(['-'] + containers))
    parser.add_argument('operation', nargs=1)
    parser.add_argument('arguments', nargs=argparse.REMAINDER)
    cmd = parser.parse_args()

    subsystem = cmd.subsystem[0]
    op = cmd.operation[0]
    args = cmd.arguments

    dockerexec = [ 'docker', 'exec', '-it' ]
    command = []

    if subsystem == '-':
        if op == 'up':
            command += [ 'docker-compose', 'up', '-d' ]
            command += args
        elif op == 'down':
            command += [ 'docker-compose', 'down' ]
            command += args
    elif op in ('/', '?', '-') and subsystem in containers:
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
        elif subsystem == 'noip':
            print ('no specific commands')
        elif subsystem == 'pihole':
            if op == 'password':
                command += [ 'pihole', '-a', '-p' ] + args
            elif op == 'status':
                command += [ 'pihole', 'status' ]
        elif subsystem in ('proxy'):
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