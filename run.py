import os
import logging
import subprocess

# Add CUDA to "PATH"
if os.path.exists('/opt/cuda/bin'):
    # Prepend '/opt/cuda/bin' to the "PATH" environment variable
    #   This makes CUDA tools available in the system path for this process
    os.environ["PATH"] = "/opt/cuda/bin:" + os.environ.get("PATH", "")

# Suppress TensorFlow INFO, WARNING, and ERROR logs
os.environ["TF_CPP_MIN_LOG_LEVEL"] = "3"
# Suppress absl logging (if used)
os.environ["ABSL_LOG_LEVEL"] = "3"
# Turn off oneDNN operations
os.environ["TF_ENABLE_ONEDNN_OPTS"] = "0"
# Set a custom directory for Matplotlib configuration files to avoid permission issues
os.environ["MPLCONFIGDIR"] = "/tmp/matplotlib"
# Restrict TensorFlow to only see the first GPU (GPU 0)
os.environ['CUDA_VISIBLE_DEVICES'] = "0"

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
        res = subprocess.run(['nvcc', '--version'], stdout=subprocess.PIPE, text=True)

        if res.returncode == 0:
            logging.info(f"CUDA is installed:\n{res.stdout}")
        else:
            logging.warning(f'NVCC Error: {res.stderr}')

    except FileNotFoundError as FnFE:
        logging.error(f'nvcc command NOT found! CUDA is not installed properly... {str(FnFE)}')


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

def checkPyTorch() -> None:
    """
    Checks the installation of PyTorch and CUDA configuration.
    Imports PyTorch and checks the available CUDA devices.

    Results are saved to the report.
    """
    logging.info(f"Checking PyTorch installation.")

    try:
        import torch    # type: ignore

        PT_VERSION: str = torch.__version__
        logging.info(f'PyTorch {PT_VERSION} installed.')

        if torch.cuda.is_available():
            logging.info(f'GPUs detected: {torch.cuda.device_count()} GPU(s)')
            for i in range(torch.cuda.device_count()):
                logging.info(f':{torch.cuda.get_device_name(i)}')
        else:
            logging.warning(f"PyTorch DID NOT detect any GPUs!")

    except ImportError as ImE:
        logging.error(f'PyTorch is NOT installed. {str(ImE)}')

    except Exception as E:
        logging.error(f'An unexpected error occured! {str(E)}')

def main() -> None:
    logging.info(f'Starting CUDA & TensorFlow Report.')
    
    checkCUDA()
    checkTF()
    checkPyTorch()

    logging.info(f"Completed. Report has been created at '{LOG}'")


if __name__ == '__main__':
    # Execute Checks
    main()