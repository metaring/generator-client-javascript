/**
 *    Copyright 2019 MetaRing s.r.l.
 *
 *    Licensed under the Apache License, Version 2.0 (the "License");
 *    you may not use this file except in compliance with the License.
 *    You may obtain a copy of the License at
 *
 *        http://www.apache.org/licenses/LICENSE-2.0
 *
 *    Unless required by applicable law or agreed to in writing, software
 *    distributed under the License is distributed on an "AS IS" BASIS,
 *    WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
 *    See the License for the specific language governing permissions and
 *    limitations under the License.
 */

package com.metaring.generator.client_javascript.factories

import com.metaring.generator.model.data.Functionality
import java.util.List

import static extension com.metaring.generator.model.util.Extensions.toStaticFieldName

class FunctionalitiesClientFactory implements com.metaring.generator.model.factories.FunctionalitiesClientFactory {

    override getFilename() '''functionalities.js'''

    override getContent(List<Functionality> functionalities) '''
function functionalities(endPointProvider«IF functionalities.exists[it.reserved || it.restricted]», identificationDataProvider«IF functionalities.exists[it.restricted]», restrictedDataProvider«ENDIF»«ENDIF») {

  if(!endPointProvider) {
    throw 'End Point Provider must be defined';
  }

  var context = this;
  context.endPointProvider = endPointProvider;
  «IF functionalities.exists[it.reserved || it.restricted]»

  if(!identificationDataProvider) {
    throw 'Identification Data Provider must be defined';
  }
  context.identificationDataProvider = identificationDataProvider;
  «ENDIF»
  «IF functionalities.exists[it.restricted]»

  if(!restrictedDataProvider) {
    throw 'Restricted Data Provider must be defined';
  }
  context.restrictedDataProvider = restrictedDataProvider;
  «ENDIF»
  «FOR functionality : functionalities»

  context.«functionality.fullyQualifiedName.toString.replace(".", "_").toStaticFieldName» = function(«IF functionality.input !== null»input, «ENDIF»data, callback) {
    data && (typeof data).toLowerCase() === 'function' && (callback = data) && (data = null);
    return new Promise(«IF functionality.reserved || functionality.restricted»async «ENDIF»function(accept, refuse) {
      try {
        «IF functionality.reserved || functionality.restricted»var identificationData = context.identificationDataProvider();
        identificationData && identificationData instanceof Promise && (identificationData = await identificationData);
        identificationData = identificationData || null;«ENDIF»
        «IF functionality.restricted»var enableData = context.restrictedDataProvider();
        enableData && enableData instanceof Promise && (enableData = await enableData);
        enableData = enableData || null;«ENDIF»
        setTimeout(async function() {
          var internalCallback = function(response, request) {
            accept(response);
            callback && callback(response, request);
          };
          try {
            var req = {
              id : parseInt((Math.random() * new Date().getTime() * Math.random() + new Date().getTime()).toString().split('.').join()),
              data : data || null,
              name : "«functionality.fullyQualifiedName»"«IF functionality.reserved || functionality.restricted || functionality.input !== null»,«ENDIF»
              «IF functionality.reserved || functionality.restricted»identificationData«IF functionality.restricted || functionality.input !== null»,«ENDIF»«ENDIF»
              «IF functionality.restricted»enableData«IF functionality.input !== null»,«ENDIF»«ENDIF»
              «IF functionality.input !== null»param : input || null«ENDIF»
            };
            var res = context.endPointProvider(req, internalCallback);
            res && res instanceof Promise && (res = await res);
            res && internalCallback(res, req);
          } catch(e) {
            return refuse(e);
          }
        });
      } catch(e) {
        return refuse(e);
      }
    });
  };
«ENDFOR»
}'''
}