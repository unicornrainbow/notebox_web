// This is a manifest file that'll be compiled into application.js, which will include all the files
// listed below.
//
// Any JavaScript/Coffee file within this directory, lib/assets/javascripts, vendor/assets/javascripts,
// or vendor/assets/javascripts of plugins, if any, can be referenced here using a relative path.
//
// It's not advisable to add code directly here, but if you do, it'll appear at the bottom of the
// compiled file.
//
// Read Sprockets README (https://github.com/sstephenson/sprockets#sprockets-directives) for details
// about supported directives.
//
//= require require
//= require angular
//= require_self
//= require jquery
//= require jquery_ujs
//= require bootstrap
//= require lib/waterfall
//= require lib/jquery.magnific_popup
//= require nprogress
//= require ace/ace
//= require xdate
//
//= require_tree ./templates
//= require_tree ./controllers
//= require_tree ./directives

app = angular.module("app", ["templates"])

//NProgress.configure({
  //showSpinner: false,
  //ease: 'ease',
  //speed: 500
//})
