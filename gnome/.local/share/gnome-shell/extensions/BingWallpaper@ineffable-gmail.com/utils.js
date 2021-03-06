// Bing Wallpaper GNOME extension
// Copyright (C) 2017-2021 Michael Carroll
// This extension is free software: you can redistribute it and/or modify
// it under the terms of the GNU Lesser General Public License as published by
// the Free Software Foundation, either version 3 of the License, or
// (at your option) any later version.
// See the GNU General Public License, version 3 or later for details.
// Based on GNOME shell extension NASA APOD by Elia Argentieri https://github.com/Elinvention/gnome-shell-extension-nasa-apod

const Gio = imports.gi.Gio;
const GLib = imports.gi.GLib;
const ExtensionUtils = imports.misc.extensionUtils;
const Soup = imports.gi.Soup;
const Me = imports.misc.extensionUtils.getCurrentExtension();
const Lang = imports.lang;
const Config = imports.misc.config;
const GdkPixbuf = imports.gi.GdkPixbuf;

const Convenience = Me.imports.convenience;
const Gettext = imports.gettext.domain('BingWallpaper');
const _ = Gettext.gettext;

let httpSession = new Soup.SessionAsync();
Soup.Session.prototype.add_feature.call(httpSession, new Soup.ProxyResolverDefault());

const PRESET_GNOME_DEFAULT = { blur: 60, dim: 60 }; // fixme: double check this
const PRESET_NO_BLUR = { blur: 0, dim: 60 }; // fixme: double check this
const PRESET_SLIGHT_BLUR = { blur: 2, dim: 60 }; // fixme: double check this

var shellVersionMajor = parseInt(imports.misc.config.PACKAGE_VERSION.split('.')[0]);
var shellVersionMinor = parseInt(imports.misc.config.PACKAGE_VERSION.split('.')[1]); //FIXME: these checks work will probably break on newer shell versions
var shellVersionPoint = parseInt(imports.misc.config.PACKAGE_VERSION.split('.')[2]);

var vertical_blur = null;
var horizontal_blur = null;

// remove this when dropping support for < 3.33, see https://github.com/OttoAllmendinger/
var getActorCompat = (obj) =>
	Convenience.currentVersionGreaterEqual("3.33") ? obj : obj.actor;

var icon_list = ['bing-symbolic', 'brick-symbolic', 'high-frame-symbolic', 'mid-frame-symbolic', 'low-frame-symbolic'];
var resolutions = ['auto', 'UHD', '1920x1200', '1920x1080', '1366x768', '1280x720', '1024x768', '800x600'];
var markets = ['ar-XA', 'da-DK', 'de-AT', 'de-CH', 'de-DE', 'en-AU', 'en-CA', 'en-GB',
	'en-ID', 'en-IE', 'en-IN', 'en-MY', 'en-NZ', 'en-PH', 'en-SG', 'en-US', 'en-WW', 'en-XA', 'en-ZA', 'es-AR',
	'es-CL', 'es-ES', 'es-MX', 'es-US', 'es-XL', 'et-EE', 'fi-FI', 'fr-BE', 'fr-CA', 'fr-CH', 'fr-FR',
	'he-IL', 'hr-HR', 'hu-HU', 'it-IT', 'ja-JP', 'ko-KR', 'lt-LT', 'lv-LV', 'nb-NO', 'nl-BE', 'nl-NL',
	'pl-PL', 'pt-BR', 'pt-PT', 'ro-RO', 'ru-RU', 'sk-SK', 'sl-SL', 'sv-SE', 'th-TH', 'tr-TR', 'uk-UA',
	'zh-CN', 'zh-HK', 'zh-TW'];
var marketName = [
	"(?????? ?????????????? ?????????????????) ??????????????", "dansk (Danmark)", "Deutsch (??sterreich)",
	"Deutsch (Schweiz)", "Deutsch (Deutschland)", "English (Australia)", "English (Canada)",
	"English (United Kingdom)", "English (Indonesia)", "English (Ireland)", "English (India)", "English (Malaysia)",
	"English (New Zealand)", "English (Philippines)", "English (Singapore)", "English (United States)",
	"English (International)", "English (Arabia)", "English (South Africa)", "espa??ol (Argentina)", "espa??ol (Chile)",
	"espa??ol (Espa??a)", "espa??ol (M??xico)", "espa??ol (Estados Unidos)", "espa??ol (Latinoam??rica)", "eesti (Eesti)",
	"suomi (Suomi)", "fran??ais (Belgique)", "fran??ais (Canada)", "fran??ais (Suisse)", "fran??ais (France)",
	"(?????????? (??????????", "hrvatski (Hrvatska)", "magyar (Magyarorsz??g)", "italiano (Italia)", "????????? (??????)", "?????????(????????????)",
	"lietuvi?? (Lietuva)", "latvie??u (Latvija)", "norsk bokm??l (Norge)", "Nederlands (Belgi??)", "Nederlands (Nederland)",
	"polski (Polska)", "portugu??s (Brasil)", "portugu??s (Portugal)", "rom??n?? (Rom??nia)", "?????????????? (????????????)",
	"sloven??ina (Slovensko)", "sloven????ina (Slovenija)", "svenska (Sverige)", "????????? (?????????)", "T??rk??e (T??rkiye)",
	"???????????????????? (??????????????)", "??????????????????", "???????????????????????????????????????", "??????????????????"
];

var BingImageURL = "https://www.bing.com/HPImageArchive.aspx?format=js&idx=0&n=8&mbl=1&mkt=";

function getSettings() {
	let extension = ExtensionUtils.getCurrentExtension();
	let schema = 'org.gnome.shell.extensions.bingwallpaper';

	const GioSSS = Gio.SettingsSchemaSource;

	// check if this extension was built with "make zip-file", and thus
	// has the schema files in a subfolder
	// otherwise assume that extension has been installed in the
	// same prefix as gnome-shell (and therefore schemas are available
	// in the standard folders)
	let schemaDir = extension.dir.get_child('schemas');
	let schemaSource;
	if (schemaDir.query_exists(null)) {
		schemaSource = GioSSS.new_from_directory(schemaDir.get_path(),
				GioSSS.get_default(),
				false);
	} else {
		schemaSource = GioSSS.get_default();
	}

	let schemaObj = schemaSource.lookup(schema, true);
	if (!schemaObj) {
		throw new Error('Schema ' + schema + ' could not be found for extension ' +
				extension.metadata.uuid + '. Please check your installation.');
	}

	return new Gio.Settings({settings_schema: schemaObj});
}

function validate_icon(settings, icon_image = null) {
	log('validate_icon()');
	let icon_name = settings.get_string('icon-name');
	if (icon_name == "" || icon_list.indexOf(icon_name) == -1) {
		settings.reset('icon-name');
		icon_name = settings.get_string('icon-name');
	}
	// if called from prefs
	if (icon_image) { 
		log('set icon to: ' + Me.dir.get_path() + '/icons/' + icon_name + '.svg');
		let pixbuf = GdkPixbuf.Pixbuf.new_from_file_at_size(Me.dir.get_path() + '/icons/' + icon_name + '.svg', 32, 32);
		icon_image.set_from_pixbuf(pixbuf);
	}
}

function validate_resolution(settings) {
	let resolution = settings.get_string('resolution');
	if (resolution == "" || resolutions.indexOf(resolution) == -1) // if not a valid resolution
		settings.reset('resolution');
}

function validate_market(settings, marketDescription = null, lastreq = null) {
	let market = settings.get_string('market');
	if (market == "" || markets.indexOf(market) == -1) { // if not a valid market
		settings.reset('market');
	}
	// only run this check if called from prefs
	let timesincelastcheck = lastreq ? GLib.DateTime.new_now_utc().difference(lastreq): 9999;
	log("last check was " + timesincelastcheck+" ms ago");

	if (marketDescription && lastreq === null || GLib.DateTime.new_now_utc().difference(lastreq)>5000) { // rate limit no more than 1 request per 5 seconds
		let request = Soup.Message.new('GET', BingImageURL + market); // + market
		log("fetching: " + BingImageURL + market);
	
		marketDescription.set_label(_("Fetching data..."));
		// queue the http request
		httpSession.queue_message(request, Lang.bind(this, function (httpSession, message) {
			if (message.status_code == 200) {
				let data = message.response_body.data;
				log("Recieved " + data.length + " bytes");
				let checkData = JSON.parse(data);
				let checkStatus = checkData.market.mkt;
				if (checkStatus == market) {
					marketDescription.set_label('Data OK, ' + data.length + ' bytes recieved');
				} else {
					marketDescription.set_label(_("Market not available in your region"));
				}
			} else {
				log("Network error occured: " + message.status_code);
				marketDescription.set_label(_("A network error occured") + ": " + message.status_code);
			}
		}));
	}
}

function get_current_bg(schema) {
	let gsettings = new Gio.Settings({ schema: schema });
	let cur = gsettings.get_string('picture-uri');
	return (cur);
}

let gitreleaseurl = 'https://api.github.com/repos/neffo/bing-wallpaper-gnome-extension/releases/tags/';

function fetch_change_log(version, label) {
	// create an http message
	let url = gitreleaseurl + "v" + version;
	let request = Soup.Message.new('GET', url);
	httpSession.user_agent = 'User-Agent: Mozilla/5.0 (X11; Ubuntu; Linux x86_64; rv:'+version+') BingWallpaper Gnome Extension';
	log("Fetching "+url);
	// queue the http request
	httpSession.queue_message(request, Lang.bind(this, function (httpSession, message) {
		if (message.status_code == 200) {
			let data = message.response_body.data;
			text = JSON.parse(data).body;
			label.set_label(text);
		} 
		else {
			log("Change log not found: " + message.status_code + "\n" + message.response_body.data);
			label.set_label(_("No change log found for this release") + ": " + message.status_code);
		}
	}));
}

function set_blur_preset(settings, preset) {
    settings.set_int('lockscreen-blur-strength', preset.blur);
	settings.set_int('lockscreen-blur-brightness', preset.dim);
	log("Set blur preset to "+preset.blur+" brightness to "+preset.dim);
}

function is_x11() {
	return GLib.getenv('XDG_SESSION_TYPE') == 'x11'; // don't do wayland unsafe things if set
}

function gnome_major_version() {
	let [major] = Config.PACKAGE_VERSION.split('.');
	let shellVersion = Number.parseInt(major);

	return shellVersion;
}
