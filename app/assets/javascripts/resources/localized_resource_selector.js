#= require resources/text_localized_resource
#= require resources/url_localized_resource
#= require resources/record_localized_resource
#= require resources/upload_localized_resource

onResources(function(){
  window['LocalizedResourceSelector']= function LocalizedResourceSelector(options, resource){
    this.options = ko.observableArray(options);
    this.current = ko.observable(options[0]);
    this.title = ko.observable('');
    this.parent = resource;
    this.language = ko.computed(function(){
      return this.current() && this.current().language()
    }, this);

    this.isValid = ko.computed(function(){
      return this.current() && this.current().isValid()
    }, this);
    this.editing = ko.computed(function(){
      return this.parent.editing()
    }, this)
  }

  LocalizedResourceSelector.prototype.toHash = function(){
    return this.current().toHash();
  }

  LocalizedResourceSelector.fromHash = function(hash, resource){
    options = _.map(['Text', 'Url', 'Record', 'Upload'], function(type){ return new window[type + "LocalizedResource"](hash, resource) });
    selector = new LocalizedResourceSelector(options, resource);

    selector.current(_.detect(options, function(option){ return option.type() == hash.type }));

    return selector
  }

  LocalizedResourceSelector.prototype.template = function() {
    return 'localized_resource_selector_template'
  }

})
