#!/usr/bin/env python
import yaml
import argparse
import os
import subprocess
import logging
import string

logger = logging.getLogger('bundle_info')


logging.addLevelName(logging.WARNING, "\033[1;31m%s" % logging.getLevelName(logging.WARNING))
logging.addLevelName(logging.ERROR, "\033[1;41m%s" % logging.getLevelName(logging.ERROR))

ch = logging.StreamHandler()
fmt = logging.Formatter('%(asctime)s %(levelname)s: %(message)s' + "\033[1;0m", datefmt='%d/%m/%Y %T')
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
    charms = {}
    for phase in bundle:
        logger.info("Parsing " + phase)
        if 'services' in bundle[phase]:
            for charm_name in bundle[phase]['services']:
                if 'branch' in bundle[phase]['services'][charm_name]:
                    charms[charm_name] = bundle[phase]['services'][charm_name]['branch']
                elif 'charm' in bundle[phase]['services'][charm_name]:
                    charms[charm_name] = bundle[phase]['services'][charm_name]['charm']
                elif 'gitrepo' in bundle[phase]['services'][charm_name]:
                    charms[charm_name] = bundle[phase]['services'][charm_name]['gitrepo']

    return charms


def component_name(charm_path):
    component = charm_path.rsplit('/')[-1]
    if component == "trunk":
        component = charm_path.rsplit('/')[-2]
    return component


def download_charms(charms, repository):
    if os.path.isdir(repository) is False:
        cmd = ['mkdir', '-p', repository]
        out = subprocess.Popen(cmd, shell=True, stdout=subprocess.PIPE, stderr=subprocess.PIPE)
        logger.debug(out.communicate())

    for charm_name in charms:
        logger.info("Downloading " + charm_name)
        origin = charms[charm_name].split(':')
        if origin[0] == "cs":
            cmd = ' '.join(['juju', 'charm', 'get', origin[1], repository])
            out = subprocess.Popen(cmd, shell=True, stdout=subprocess.PIPE, stderr=subprocess.PIPE)
            logger.debug(out.communicate())
        elif origin[0] == "lp":
            cmd = ' '.join(['bzr', 'branch', charms[charm_name], repository + '/' + charm_name])
            out = subprocess.Popen(cmd, shell=True, stdout=subprocess.PIPE, stderr=subprocess.PIPE)
            logger.debug(out.communicate())
        elif origin[0] == "git":
            cmd = ' '.join(['git', 'clone', charms[charm_name], repository + '/' + charm_name])
            out = subprocess.Popen(cmd, shell=True, stdout=subprocess.PIPE, stderr=subprocess.PIPE)
            logger.debug(out.communicate())


def get_parameters(charms, repository):
    parameters_list = []
    for charm_name in charms:
        component = component_name(charms[charm_name])
        logger.info("Parsing " + charm_name + " (" + component + ")")
        config_file = repository + '/' + component + '/config.yaml'
        if os.path.isfile(config_file) is False:
            # Fallback for certain naming conventions
            config_file = repository + '/' + charm_name + '/config.yaml'

        try:
            with open(config_file, 'r') as f:
                parameters = yaml.load(f)

            for p_name in parameters['options']:
                parameter = parameters['options'][p_name]
                if 'default' in parameter:
                    default_value = parameter['default']
                    if (bool(default_value)) and "\n" in str(default_value):
                        default_value = default_value.translate(string.maketrans("\n", " "))
                else:
                    default_value = ""
                parameter_set = [charm_name, component, charms[charm_name], p_name, parameter['type'], default_value]
                parameters_list.append(parameter_set)

        except IOError:
            logger.warning("Charm " + component + " does not include config.yaml")

    return parameters_list


def write_csv(parameters, csvfile):
    f = open(csvfile, 'w')
    csv_header = ['Service name', 'Component Name', 'Charm Path', 'Parameter Name', 'Parameter Type', 'Default value']
    csv_row = ';'.join(value for value in csv_header)
    f.write(csv_row + '\n')
    for parameter in parameters:
        csv_row = ';'.join(str(value) for value in parameter)
        f.write(csv_row + '\n')
    f.close()


def main():
    logger.setLevel(logging.INFO)
    args = read_args()

    if args.verbose is True:
        logger.setLevel(logging.DEBUG)

    with open(args.bundle, 'r') as f:
        bundle = yaml.load(f)

    logger.info(" ----- Parsing bundle " + args.bundle + " -----")
    charms = parse_bundle(bundle)
    logger.info(" ----- Downloading charms to " + args.repository + " -----")
    download_charms(charms, args.repository)
    logger.info(" ----- Parsing parameters from charms -----")
    parameters = get_parameters(charms, args.repository)
    logger.info(" ----- Writing parameters and values in CSV format: " + args.csvfile + " -----")
    write_csv(parameters, args.csvfile)


if __name__ == '__main__':
    main()
