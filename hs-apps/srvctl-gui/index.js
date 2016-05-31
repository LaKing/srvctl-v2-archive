(function() {

    var app = angular.module('app', ['ngSanitize']);

    app.run(function($rootScope) {

        // rootscope functions and variables

        $rootScope.main = {};

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

        // host index
        $scope.hix = 0;
        // container index in host index
        $scope.cix = undefined;

        $scope.terminal = 'Please wait.';

        $scope.containers = [];

        $scope.sethix = function(hix) {
            $scope.cix = undefined;
            if (hix > -1) {
                $scope.hix = hix;
                $scope.containers = $rootScope.main.hosts[hix].containers;
            } else $scope.hix = undefined;
        };
        $scope.setcix = function(cix) {
            $scope.cix = cix;

        };

        $scope.command = function(c) {
            $scope.terminal = '';

            var cmd = c;
            if (c === 'info' || c === 'start' || c === 'stop') cmd = c + ' ' + $scope.containers[$scope.cix].name;
            var cmd_json = {
                hix: $scope.hix,
                cix: $scope.cix,
                cmd: cmd
            };
            socket.emit('sc-command', cmd_json);

        };

        socket.emit('get-main');
        $scope.command('status-all');


        socket.on('set-main', function(main) {
            console.log(main);
            $rootScope.main = main;

            $scope.sethix(0);

        });
        socket.on('set-terminal', function(term) {
            //console.log(term);
            $scope.terminal = '<pre>' + term + '</pre>';
        });

    }]);



})();