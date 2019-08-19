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

import java.util.List
import com.metaring.generator.model.data.Functionality
import static extension com.metaring.generator.model.util.Extensions.toStaticFieldName
import static extension com.metaring.generator.model.util.Extensions.combineWithSystemNamespace

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

  context.«functionality.fullyQualifiedName.toString.replace(".", "_").toStaticFieldName» = function(«IF functionality.input !== null»input, «ENDIF»callback) {
    return new Promise(function(accept) {
      setTimeout(function() {
        var internalCallback = function(response, request) {
          accept(response);
          callback && callback(response, request);
        };
        context.endPointProvider({
          id : parseInt((Math.random() * new Date().getTime() * Math.random() + new Date().getTime()).toString().split('.').join()),
          name : '«IF functionality.reserved || functionality.restricted»«"rpc.auth.callReserved".combineWithSystemNamespace»«ELSE»«functionality.fullyQualifiedName»«ENDIF»',
«IF functionality.reserved || functionality.restricted || functionality.input !== null»          param : «IF !functionality.reserved && !functionality.restricted»input || null«ELSE»{
            name : '«IF functionality.restricted»«"rpc.auth.callRestricted".combineWithSystemNamespace»«ELSE»«functionality.fullyQualifiedName»«ENDIF»',
«IF functionality.reserved || functionality.restricted»            data : context.identificationDataProvider()«IF functionality.restricted || functionality.input !== null»,«ENDIF»«ENDIF»
«IF functionality.restricted || functionality.input !== null»            param : «IF !functionality.restricted»input || null«ELSE»{
              name : '«functionality.fullyQualifiedName»'«IF functionality.restricted || functionality.input !== null»,«ENDIF»
«IF functionality.restricted»              data : context.restrictedDataProvider(context.identificationDataProvider)«ENDIF»«IF functionality.input !== null»,«ENDIF»
«IF functionality.input !== null»              param : input || null«ENDIF»
            }«ENDIF»«ENDIF»
          }«ENDIF»«ENDIF»
        }, internalCallback);
      });
    });
  };
«ENDFOR»
}'''
}