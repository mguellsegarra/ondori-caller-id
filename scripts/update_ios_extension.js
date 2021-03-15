const fs = require("fs");
const dotenv = require("dotenv");
const envConfig = dotenv.parse(fs.readFileSync("./.env"));

let extensionSourceFile = fs.readFileSync(
  "./node_modules/ondori-caller-id/scripts/CallDirectoryHandler.m",
  "utf-8"
);

extensionSourceFile = extensionSourceFile.replace(
  "CALLER_LIST",
  envConfig.IOS_DATA_KEY
);
extensionSourceFile = extensionSourceFile.replace(
  "group.mguellsegarra_callerid",
  envConfig.IOS_APP_GROUP
);

fs.writeFileSync(
  envConfig.IOS_EXTENSION_FILEPATH,
  extensionSourceFile,
  "utf-8"
);
