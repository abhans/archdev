import os
import logging
import subprocess

HOME: str = os.environ['HOME']
LOG: str = f'{HOME}/report.txt'

logging.basicConfig(
    format=">>> %(asctime)s | %(msg)s -> %(name)s @ %(filename)s",
    datefmt="%H:%M:%S",
    level=logging.INFO,
    handlers=[logging.StreamHandler(), logging.FileHandler(LOG, encoding='utf-8')]
)

def checkCUDA() -> None:
    """
    Checks whether the CUDA is installed properly.
    Invokes CMD comamnds and inspects the outputs.

    Results are saved to the report.
    """
    logging.info(f"Checking CUDA installation.")
    try:
        res = subprocess.run(['nvcc --version'], stdout=subprocess.PIPE, text=True)

        if res.returncode == 0:
            logging.info(f"CUDA is installed -> NVCC:{res.stdout}")
        else:
            logging.warning(f'NVCC Error: {res.stderr}')

    except FileNotFoundError as FnF:
        logging.error('nvcc command NOT found! CUDA is Not installed properly...')


def checkTF() -> None:
    """
    Checks the installation of TensorFlow and CUDA configuration.
    Imports TensorFlow and checks the available CUDA devices.

    Results are saved to the report.
    """
    logging.info(f"Checking TensorFlow installation.")

    try:
        import tensorflow as tf      # type: ignore

        TF_VERSION: str = tf.__version__
        logging.info(f'TensorFlow {TF_VERSION} installed.')

        DEVICES = tf.config.list_physical_devices('GPU')

        if DEVICES:
            logging.info(f'GPUs detected: {len(DEVICES)} GPU(s)')
            for DEVICE in DEVICES:
                logging.info(f':{DEVICE.name}')
        # No GPU is detected
        else:
            logging.warning(f"TensorFlow DID NOT detect any GPUs!")

    except ImportError as ImE:
        logging.error(f'TensorFlow is NOT installed. {str(ImE)}')

    except Exception as E:
        logging.error(f'An unexpected error occured! {str(E)}')

def main() -> None:
    logging.info(f'Starting CUDA & TensorFlow Report.')
    
    checkCUDA()
    checkTF()

    logging.info(f"Completed. Report has been created at '{LOG}'")


if __name__ == '__main__':
    # Execute Checks
    main()