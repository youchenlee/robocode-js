$ENABLE_DEBUG = false

if !console
    console = {
        log: (msg) ->
            data = {"log": msg}
            postMessage JSON.stringify data
    }

logger = {}
logger.log = (msg) ->
    if $ENABLE_DEBUG
        console.log msg
