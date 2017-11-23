#!/usr/bin/env python2.7
# -*- coding: utf-8 -*-

import ed25519  # https://ed25519.cr.yp.to/python/ed25519.py
from random import randrange

# Generates random inputs and their correct results for testing

skfile = open('./skfile.dat', 'w')
pkfile = open('./pkfile.dat', 'w')
mfile = open('./mfile.dat', 'w')
sfile = open('./sfile.dat', 'w')
rfile = open('./rfile.dat', 'w')

for i in range(100):
    sk = randrange(0, 2**256 - 1)
    sk = ('%064x' % sk).decode('hex')
    M = randrange(0, 2**256 - 1)
    M = ('%064x' % M).decode('hex')
    A = ed25519.publickey(sk)
    sig = ed25519.signature(M, sk, A)

#     print 'sk: %s' % sk.encode('hex')
#     print 'M: %s' % M.encode('hex')
#     print 'A: %s' % A.encode('hex')
#     print 'R: %s' % sig[:32].encode('hex')
#     print 'S: %s' % sig[32:].encode('hex')

    skfile.write(sk.encode('hex') + '\n')
    mfile.write(M.encode('hex') + '\n')
    pkfile.write(A.encode('hex') + '\n')
    rfile.write(sig[:32].encode('hex') + '\n')
    sfile.write(sig[32:].encode('hex') + '\n')
