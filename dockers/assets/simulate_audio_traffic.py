import logging
import random
import socket
import subprocess
import threading
import time

import bitstruct as bitstruct

PORT = 5555
BUFFER_SIZE = 3000
FFMPEG_LOCATION = "/home/pi/ffmpeg"
FFMPEG_LOCATION = ""


class FakeRecorder(threading.Thread):
    def __init__(self):
        super().__init__(name="FakeRecorder")
        self.running = True
        self.seqnum = 0
        self.destination = "224.10.22.31"
        self.ffmpeg = None  # type: subprocess.Popen
        self.port = random.randint(1200, 1400)
        self.sock = None
        self.transmission = None

    def run(self):
        cf = bitstruct.compile("u16u24")
        LOGGER = logging.getLogger(__name__)
        LOGGER.debug("(recorder %s): %s" % (self.destination, "started"))
        self._initial_setup(LOGGER)

        while self.running:
            try:
                data = self.sock.recv(BUFFER_SIZE)
                timestamp = int(time.time() * 1000) % (2 ** 24)
                headers = cf.pack(self.seqnum, timestamp)
                data = headers + data
                LOGGER.log(9, "(recorder %s): sending %d bytes with seqnum %d recorded at %d" % (self.destination,
                                                                                                 len(data), self.seqnum,
                                                                                                 timestamp))
                self.seqnum += (self.seqnum + 1) % (2 ** 16)
                self.transmission.sendto(data, (self.destination, 5555))
            except Exception as e:
                LOGGER.exception("Exception while capturing: %s" % str(e))
                # if we have a error here something is going with the headset connection...
                LOGGER.error("Going to reset")
                self._cleanup()
                self._initial_setup(LOGGER)
        self._cleanup()

    def _initial_setup(self, _logger):
        self.sock = socket.socket(socket.AF_INET, socket.SOCK_DGRAM)
        self.transmission = socket.socket(socket.AF_INET, socket.SOCK_DGRAM)
        self.sock.bind(("localhost", self.port))
        self.sock.settimeout(10)

        output = "udp://127.0.0.1:%d" % self.port  # localhost brakes it :(
        file = "audio.mp3"
        self.ffmpeg = subprocess.Popen(
            [FFMPEG_LOCATION + "ffmpeg", "-re", "-stream_loop", "-1", "-i", file, "-acodec", "libopus"] +
            ["-b:a", "26k", "-packet_loss", "10", "-application", "voip"] +
            ["-f", "mpegts", output])

        _logger.debug("(fake playing to %s): file %s" % (self.destination, file))

    def _cleanup(self):
        tries = 0
        while self.ffmpeg and not self.ffmpeg.poll() and tries < 5:
            self.ffmpeg.terminate()
            time.sleep(0.1)
            self.ffmpeg.kill()
            tries += 1
        self.ffmpeg = None

    def stop(self):
        self.running = False

    def get_seq_number(self):
        return self.seqnum


if __name__ == "__main__":
    rec = FakeRecorder()
    rec.start()

    try:
        while True:
            time.sleep(1e8)
    except KeyboardInterrupt:
        pass
    rec.stop()
