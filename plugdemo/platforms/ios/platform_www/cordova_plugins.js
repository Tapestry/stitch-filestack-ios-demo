cordova.define('cordova/plugin_list', function(require, exports, module) {
module.exports = [
  {
    "id": "cordova-plugin-filestack.filestack",
    "file": "plugins/cordova-plugin-filestack/www/filestack.js",
    "pluginId": "cordova-plugin-filestack",
    "clobbers": [
      "window.filepicker"
    ]
  }
];
module.exports.metadata = 
// TOP OF METADATA
{
  "cordova-plugin-filestack": "0.0.9"
};
// BOTTOM OF METADATA
});