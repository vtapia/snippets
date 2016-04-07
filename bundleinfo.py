#!/usr/bin/env python
import yaml
import argparse
import os
import subprocess
import logging


logger = logging.getLogger('bundle_info')

ch = logging.StreamHandler()
fmt = logging.Formatter('%(asctime)s %(levelname)s: [bundle_info] %(message)s', datefmt='%d/%m/%Y %T')
ch.setFormatter(fmt)
logger.addHandler(ch)


def read_args():

    parser = argparse.ArgumentParser()
    parser.add_argument('-b', '--bundle', help='Bundle file', required=True)
    parser.add_argument('-r', '--repository', help='Charms repository directory', required=True)
    parser.add_argument('-c', '--csvfile', help='CSV output file', required=True)
    parser.add_argument('-v', '--verbose', help='Show debug messages', action="store_true")
    args = parser.parse_args()

    return args


def parse_bundle(bundle):
    charms = []
    for charm_name in bundle['openstack-services']['services']:
        charms.append(charm_name)

    return charms


def download_charms(charms, repository):
    if os.path.isdir(repository) is False:
        cmd = ['mkdir', '-p', repository]
        out = subprocess.Popen(cmd, shell=True, stdout=subprocess.PIPE, stderr=subprocess.PIPE)
        logger.debug(out.communicate())

    for charm_name in charms:
        cmd = ' '.join(['juju', 'charm', 'get', charm_name, repository])
        out = subprocess.Popen(cmd, shell=True, stdout=subprocess.PIPE, stderr=subprocess.PIPE)
        logger.debug(out.communicate())


def get_parameters(charms, repository):
    parameters_list = []
    for charm_name in charms:
        config_file = repository + '/' + charm_name + '/config.yaml'

        with open(config_file, 'r') as f:
            parameters = yaml.load(f)

        for p_name in parameters['options']:
            parameter = parameters['options'][p_name]
            parameter_set = [charm_name, p_name, parameter['type'], parameter['default']]
            parameters_list.append(parameter_set)

    return parameters_list


def write_csv(parameters, csvfile):
    f = open(csvfile, 'w')
    csv_header = ['Component name', 'Parameter Name', 'Parameter Type', 'Default value']
    csv_row = ','.join(value for value in csv_header)
    f.write(csv_row + '\n')
    for parameter in parameters:
        csv_row = ','.join(str(value) for value in parameter)
        f.write(csv_row + '\n')
    f.close()


def main():
    logger.setLevel(logging.INFO)
    args = read_args()

    if args.verbose is True:
        logger.setLevel(logging.DEBUG)

    with open(args.bundle, 'r') as f:
        bundle = yaml.load(f)

    logger.info("Parsing bundle " + args.bundle)
    charms = parse_bundle(bundle)
    logger.info("Downloading charms to " + args.repository)
    download_charms(charms, args.repository)
    logger.info("Parsing parameters from charms")
    parameters = get_parameters(charms, args.repository)
    logger.info("Writing parameters and values in CSV format: " + args.csvfile)
    write_csv(parameters, args.csvfile)


if __name__ == '__main__':
    main()
