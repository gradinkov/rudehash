// This file is required by the index.html file and will
// be executed in the renderer process for that window.
// All of the Node.js APIs are available in this process.

const {app} = require('electron').remote;
const path = require('path');
const fs = require('fs');
var $configDirPath = path.join(app.getPath('appData'), 'RudeHash');
var $configFilePath = path.join($configDirPath, 'rudehash.json');

/* to have a single config folder, electron app name is also RudeHash
 * we don't have to worry about the dir, it is created when the app is started
 */
// fs.mkdirSync($configDirPath);

var $rudeSchema =
{
  "title": "Config",
  "type": "object",
  "properties": {
    "Worker": {
      "type": "string",
      "description": "Your rig's nickname.",
      "minLength": 1,
      "default": "rudehash",
      "required": true
    },
    "Currency": {
      "type": "string",
      "description": "Your currency's symbol.",
      "minLength": 1,
      "default": "USD",
      "required": true
    },
    "ElectricityCost": {
      "type": "number",
      "description": "The price you pay for electricity, &lt;your currency&gt;/kWh, decimal separator is '.'",
      "minLength": 1,
      "default": "0.1",
      "required": true
    },
    "MonitoringKey": {
      "type": "string",
      "description": "Allows for monitoring your rigs at rudehash.org/monitor. <button id=\"uuid\" onclick=\"fill_uuid()\">Generate one</a>",
      "minLength": 0,
      "id": "monitoringkey",
      "maxLength": 36,
      "default": "",
      "required": false
    },
    "MphApiKey": {
      "type": "string",
      "description": "Allows for monitoring at miningpoolhubstats.com using your <a href=\"https://miningpoolhub.com/?page=account&action=edit\" target=\"_blank\">MPH API key</a>.",
      "minLength": 0,
      "maxLength": 64,
      "default": "",
      "required": false
    },
    "Debug": {
      "type": "boolean",
      "description": "If true, RudeHash will print diagnostic information along with the rest. Useful for troubleshooting.",
      "required": true,
      "default": false
    },
    "ActiveProfile": {
      "id": "ActiveProfile",
      "type": "integer",
      "description": "RudeHash profile currently in use.",
      "minLength": 1,
      "default": 1,
      "required": true
    },
    "Profiles": {
      "type": "array",
      "format": "tabs",
      "title": "Profiles",
      "uniqueItems": true,
      "minItems" : 1,
      "required": true,
      "items": {
        "type": "object",
        "title": "Profile",
        "properties": {
          "Pool": {
            "type": "string",
            "description": "The pool you want to mine on.",
            "enum": [
              "bsod",
              "masterhash",
              "miningpoolhub",
              "nicehash",
              "poolr",
              "suprnova",
              "zergpool",
              "zpool"
            ],
            "required": true
          },
          "Algo": {
            "type": "string",
            "description": "The algo you want to mine in. Ignored if coin is set.",
            "enum": [
              "allium",
              "bitcore",
              "ethash",
              "equihash",
              "hsr",
              "keccakc",
              "lyra2v2",
              "lyra2z",
              "neoscrypt",
              "nist5",
              "phi",
              "phi2",
              "polytimos",
              "skein",
              "tribus",
              "x16r",
              "x16s",
              "xevan"
            ],
            "required": false
          },
          "Coin": {
            "type": "string",
            "description": "The coin you want to mine. If unset, you must select an algo instead.",
            "enum": [
              "bsd",
              "btcp",
              "btg",
              "btx",
              "bwk",
              "crea",
              "crs",
              "dnr",
              "eth",
              "flm",
              "ftc",
              "gin",
              "grlc",
              "hsr",
              "ifx",
              "kreds",
              "lux",
              "mona",
              "pgn",
              "poly",
              "rvn",
              "tzc",
              "vtc",
              "xlr",
              "xzc",
              "zcl",
              "zec",
              "zen"
            ],
            "required": false
          },
          "Miner": {
            "type": "string",
            "description": "The miner you want to use.",
            "enum": [
              "ccminer-alexis-hsr",
              "ccminer-allium",
              "ccminer-klaust",
              "ccminer-palginmod",
              "ccminer-phi",
              "ccminer-polytimos",
              "ccminer-rvn",
              "ccminer-tpruvot",
              "ccminer-xevan",
              "dstm",
              "ethminer",
              "excavator",
              "hsrminer-hsr",
              "hsrminer-neoscrypt",
              "nevermore-x16s",
              "suprminer",
              "vertminer",
              "zecminer"
            ],
            "required": true
          },
          "Watchdog": {
            "type": "boolean",
            "description": "If true, RudeHash will restart the miner if it reports 0 hashrate for 5 consecutive minutes.",
            "required": true,
            "default": true
          },
          "Wallet": {
            "type": "string",
            "description": "Your Bitcoin or Altcoin wallet. Ignored on pools that use a site balance.",
            "required": false,
            "default": ""
          },
          "WalletIsAltcoin": {
            "type": "boolean",
            "description": "If true, your wallet's currency is the same as the coin you're mining, and you're paid directly to this wallet for mining a coin. If false, your wallet is Bitcoin, and the pool auto-exchanges the mined coins to BTC. Ignored on pools that use a site balance.",
            "required": true,
            "default": false
          },
          "User": {
            "type": "string",
            "description": "Pool user name. Ignored on pools that use a wallet address.",
            "required": false,
            "default": ""
          },
          "Region": {
            "type": "string",
            "description": "Pool region. Only required on pools that have regions.",
            "required": false,
            "default": ""
          },
          "ExtraArgs": {
            "type": "string",
            "description": "Any additional command line arguments you want to pass to the miner.",
            "required": false,
            "default": ""
          }
        }
      },
      "default": [
        {
          "Pool": "zpool",
          "Algo": "hsr",
          "Coin": "",
          "Miner": "ccminer-alexis-hsr",
          "Wallet": "1HFapEBFTyaJ74SULTJ5oN5BK3C5AYHWzk",
          "WalletIsAltcoin": false
        }
      ]
    }
  }
};

var $element = document.getElementById('editor');
var $output = document.getElementById('output');
//var $set_value_button = document.getElementById('setvalue');
var $save_button = document.getElementById('save');
var $export_button = document.getElementById('export');
var $file_input = document.getElementById('file-input')
var $validate = document.getElementById('validate');

var $editor = new JSONEditor($element, {
  schema: $rudeSchema,
  theme: 'bootstrap3',
  iconlib: 'foundation3',
  disable_edit_json: true,
  disable_properties: true,
  disable_collapse: true,
  disable_array_delete_all_rows: true,
  disable_array_delete_last_row: true,
  no_additional_properties: true
});

function update_output() {
  $output.value = JSON.stringify($editor.getValue(),null,2);

  var $validation_errors = $editor.validate();

  /* Show validation errors if there are any */
  if($validation_errors.length) {
      $validate.value = JSON.stringify($validation_errors,null,2);
  }
  else {
      $validate.value = 'The configuration syntax is valid.';
  }
}

/* update JSON when config changes */
$editor.on('change', update_output);

/* update config from JSON when button clicked */
//$set_value_button.addEventListener('click',function() {
//  $editor.setValue(JSON.parse($output.value));
//});

/* option to load existing JSON file */
function readSingleFile($e) {
  var $file = $e.target.files[0];

  if (!$file) {
    return;
  }

  var $reader = new FileReader();

  $reader.onload = function($e) {
    /* unnecessary, editor change triggers update_output anyway */
    //$output.value = $e.target.result;
    $editor.setValue(JSON.parse($e.target.result));
  };

  $reader.readAsText($file);
}

function readConfigFile()
{
  fs.readFile($configFilePath, 'utf-8', (err, data) =>
  {
    if(err)
    {
        alert("An error ocurred reading the file :" + err.message);
        return;
    }

    $editor.setValue(JSON.parse(data));
  });
}

if (fs.existsSync($configFilePath))
{
  readConfigFile();
}

$file_input.addEventListener('change', readSingleFile, false);

/* file download */
function downloadJson ($e) {
  /* application/octet-stream: filename is broken
   * application/json: opens in browser
   */
  //uriContent = "data:application/json," + encodeURIComponent(JSON.stringify($editor.getValue(),null,2));
  //newWindow = window.open(uriContent, 'rudehash');

  var $jsonText = JSON.stringify($editor.getValue(),null,2)
  var $pom = document.createElement('a');
  $pom.setAttribute('href', 'data:application/json;charset=utf-8,' + encodeURIComponent($jsonText));
  $pom.setAttribute('download', 'rudehash.json');

  if (document.createEvent) {
    var event = document.createEvent('MouseEvents');
    event.initEvent('click', true, true);
    $pom.dispatchEvent(event);
  }
  else {
    $pom.click();
  }
}

function saveConfigFile()
{
  fs.writeFile($configFilePath, JSON.stringify($editor.getValue(),null,2), (err) => {
      if (err) {
          alert("An error ocurred updating the file" + err.message);
          console.log(err);
          return;
      }

      //alert("The file has been succesfully saved");
  });
}

$save_button.addEventListener('click', saveConfigFile);
$export_button.addEventListener('click', downloadJson);

function uuidv4() {
  return ([1e7]+-1e3+-4e3+-8e3+-1e11).replace(/[018]/g, c =>
    (c ^ crypto.getRandomValues(new Uint8Array(1))[0] & 15 >> c / 4).toString(16)
  )
}

function fill_uuid() {
  /* this would trim any properties that are empty yet */
  //$editor.setValue({MonitoringKey: uuidv4()});

  var $MonitoringKey = $editor.getEditor('root.MonitoringKey');

  if($MonitoringKey)
  {
    $MonitoringKey.setValue(uuidv4());
  }
}

/* make sure the user selects a profile that actually exists */
JSONEditor.defaults.custom_validators.push(function(schema, value, path) {
  var errors = [];
  if(schema.id == "ActiveProfile")
  {
    $activeProf = $editor.getEditor("root.ActiveProfile").value;
    $profileCount = $editor.getEditor("root.Profiles").rows.length;

    if ($activeProf > $profileCount || $activeProf < 1) {
      errors.push({
        path: path,
        property: 'ActiveProfile',
        message: "The selected profile (" + $activeProf + ") doesn't exist!"
      });
    }
  }

  return errors;
});
