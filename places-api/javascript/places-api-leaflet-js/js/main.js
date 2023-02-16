


$(document).ready(function() {

  // Initialize leaflet map
  var map = L.map('map').setView([0, 0], 2);
  var layerGroup = L.layerGroup().addTo(map);

    // Set up submit button to call api
    $(" #submit-button ").click(function(){

      //Get form and create query string
      const formElem = document.querySelector('form');
      const queryString = new URLSearchParams(new FormData(formElem)).toString()
      console.log(queryString)

      //Clear previous markers
      layerGroup.clearLayers();

      // AJAX Settings
      const settings = {
        "async": true,
        "crossDomain": true,
        "url": "https://api.foursquare.com/v3/places/search?"+ queryString,
        "method": "GET",
        "headers": {
          "Accept": "application/json",
          "Authorization": "FSQ_API_KEY"
        }
      };

    $.ajax(settings).done(function (response) {
        console.log(response.results);
     
        //Loop through results and add markers to map
        response.results.forEach( i => {
          if( i.geocodes.main.latitude != null && i.geocodes.main.longitude != null){
            var marker = L.marker([i.geocodes.main.latitude, i.geocodes.main.longitude], {"alt": i.name, "autoPanOnFocus": true, "pane": 'markerPane'}).addTo(layerGroup).bindPopup(i.name);
            
          }
        })

        // Zoom in to where markers are located
        map.flyTo([response.results[0].geocodes.main.latitude, response.results[0].geocodes.main.longitude], 10)  
      });
      
   
    })

    //Set map on page
    L.tileLayer('https://{s}.tile.openstreetmap.org/{z}/{x}/{y}.png', {
      maxZoom: 19,
      attribution: '© OpenStreetMap'
      }).addTo(map);



});
  









