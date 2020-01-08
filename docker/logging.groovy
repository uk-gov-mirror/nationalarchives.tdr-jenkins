import java.util.logging.LogManager
import java.util.logging.Logger
import java.util.logging.Level

def logger = Logger.getLogger("hudson.TcpSlaveAgentListener")
logger.setLevel(Level.WARNING)
LogManager.getLogManager().addLogger(logger)