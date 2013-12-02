require 
  shim:
    'directives/modal': deps: ['index']
    'directives/dataTable': deps: ['index']
    'directives/dataTable2': deps: ['index']
    'directives/select2': deps: ['index']
    'directives/fileUpload': deps: ['index']
    'services/fileManager': deps: ['index']
    'views': deps: ['index']
  [
    'index'
    'directives/modal'
    'directives/dataTable'
    'directives/dataTable2'
    'directives/select2'
    'directives/fileUpload'
    'services/fileManager'
    'views'
  ], () ->
    return