(function() {

    var app = angular.module('app', ['ngSanitize']);

    app.run(function($rootScope) {

        // rootscope functions and variables

        $rootScope.lock = false;

    });

    app.factory('socket', function($rootScope) {
        var socket = io.connect();
        return {
            on: function(eventName, callback) {
                socket.on(eventName, function() {
                    var args = arguments;
                    $rootScope.$apply(function() {
                        callback.apply(socket, args);
                    });
                });
            },
            emit: function(eventName, data, callback) {
                socket.emit(eventName, data, function() {
                    var args = arguments;
                    $rootScope.$apply(function() {
                        if (callback) {
                            callback.apply(socket, args);
                        }
                    });
                });
            }
        };
    });


    app.controller('mainController', ['$scope', '$http', '$rootScope', 'socket', function($scope, $http, $rootScope, socket) {
        $scope.main = {};
        // host index
        $scope.hix = 0;
        // container index in host index
        $scope.cix = undefined;

        $scope.terminal = 'Please wait.';

        $scope.containers = [];
        $scope.modal = {};

        $scope.reset_modal = function() {
            $scope.modal = {
                title: "",
                argument_txt: '',
                has_opa: false,
                optional_txt: '',
                command: '',
                argument: '',
                optional: ''
            };
        };
        $scope.reset_modal();

        $scope.is_fqdn = function(val) {
            if (/^[a-zA-Z0-9][a-zA-Z0-9-]{1,61}[a-zA-Z0-9](?:\.[a-zA-Z]{2,})+$/.test(val)) {
                return true;
            } else {
                return false;
            }
        };

        $scope.sethix = function(hix) {
            $scope.cix = undefined;
            if (hix > -1) {
                $scope.hix = hix;
                $scope.containers = $scope.main.hosts[hix].containers;
            } else $scope.hix = undefined;
        };
        $scope.setcix = function(cix) {
            $scope.cix = cix;

        };

        $scope.command = function(c) {
            if ($rootScope.lock) {
                alert("Please wait.");
                return;
            }
            $scope.terminal = '';
            $rootScope.lock = true;

            var cmd = c;
            var cmd_json = {
                hix: $scope.hix,
                cmd: cmd
            };
            socket.emit('sc-command', cmd_json);

        };
        $scope.command_ve = function(c) {
            if ($rootScope.lock) {
                alert("Please wait.");
                return;
            }
            $scope.terminal = '';
            $rootScope.lock = true;

            var cmd = c + ' ' + $scope.containers[$scope.cix].name;
            var cmd_json = {
                hix: $scope.hix,
                cmd: cmd
            };
            socket.emit('sc-command', cmd_json);

        };

        socket.emit('get-main');
        $scope.command('status');


        socket.on('set-main', function(main) {
            console.log(main);
            $scope.main = main;

            $scope.sethix(0);

        });
        socket.on('set-terminal', function(term) {
            //console.log(term);
            $scope.terminal = '<pre>' + term + '</pre>';
        });
        socket.on('lock', function(status) {
            $rootScope.lock = status;
        });
    }]);



})();