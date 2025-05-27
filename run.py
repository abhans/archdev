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
LOG: str = f'{HOME}/report.log'

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
        nvccRes = subprocess.run(['nvcc', '--version'], stdout=subprocess.PIPE, text=True)
        
        if nvccRes.returncode == 0:
            logging.info(f"CUDA is installed:\n{nvccRes.stdout}")
        else:
            logging.warning(f'NVCC & NVIDIA Error: {nvccRes.stderr}')
    
    except FileNotFoundError as FnFE:
        logging.error(f'nvcc command NOT found! CUDA is not installed properly... {str(FnFE)}')
    
    except Exception as E:
        logging.error(f'An unexpected error occurred while checking CUDA: {str(E)}')


def checkSMI() -> None:
    """
    Checks whether the NVIDIA System Management Interface (SMI) is installed.
    Invokes CMD commands and inspects the outputs.

    Results are saved to the report.
    """
    logging.info(f"Checking NVIDIA SMI installation.")
    try:
        smiRes = subprocess.run(['nvidia-smi'], stdout=subprocess.PIPE, text=True)
        
        if smiRes.returncode == 0:
            logging.info(f"{smiRes.stdout}")
        else:
            logging.warning(f'NVIDIA SMI Error: {smiRes.stderr}')
    
    except FileNotFoundError as FnFE:
        logging.error(f'nvidia-smi command NOT found! NVIDIA drivers are not installed properly... {str(FnFE)}')
    
    except Exception as E:
        logging.error(f'An unexpected error occurred while checking NVIDIA SMI: {str(E)}')

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
                details = tf.config.experimental.get_device_details(DEVICE)
                logging.info(f':{details.get('device_name', 'Unknown Device')}')
        # No GPU is detected
        else:
            logging.warning(f"TensorFlow DID NOT detect any GPUs!")

    except ImportError as ImE:
        logging.error(f'TensorFlow is NOT installed. {str(ImE)}')

    except Exception as E:
        logging.error(f'An unexpected error occured! {str(E)}')

def checkTorch() -> None:
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
    logging.info(f'Starting System Report.')
    
    checkCUDA()
    checkSMI()
    checkTF()
    checkTorch()
    # checkOpenCV()

    logging.info(f"Completed. Report has been created at '{LOG}'")

# TODO: Resolve the connectivity issues with OpenCV
# def checkOpenCV() -> None:
#     """
#     Checks the installation of OpenCV and its access to the camera.
#     Imports OpenCV and attempts to access the camera.

#     Results are saved to the report.    
#     """
#     try:
#         import cv2  # type: ignore
#         CV2_VERSION: str = cv2.__version__
#         logging.info(f'OpenCV {CV2_VERSION} installed.')
    
#         try:
#             capture = cv2.VideoCapture(0)
#             if capture.isOpened():
#                 logging.info(f'OpenCV can access the camera: {capture.get(cv2.CAP_PROP_FPS)} FPS')
#             else:
#                 logging.warning('OpenCV cannot access the camera.')
#             capture.release()
#         except Exception as E:
#             logging.error(f'An error occurred while checking OpenCV camera access: {str(E)}')

#     except ImportError as ImE:
#         logging.error(f'OpenCV is NOT installed. {str(ImE)}')

if __name__ == '__main__':
    # Execute Checks
    main()