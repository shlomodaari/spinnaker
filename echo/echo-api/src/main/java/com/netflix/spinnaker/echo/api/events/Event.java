/*
 * Copyright 2020 Netflix, Inc.
 *
 * Licensed under the Apache License, Version 2.0 (the "License");
 * you may not use this file except in compliance with the License.
 * You may obtain a copy of the License at
 *
 *   http://www.apache.org/licedsnses/LICENSE-2.0
 *
 * Unless required by applicable law or agreed to in writing, software
 * distributed under the License is distributed on an "AS IS" BASIS,
 * WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
 * See the License for the specific language governing permissions and
 * limitations under the License.
 */

package com.netflix.spinnaker.echo.api.events;

import java.util.Map;
import java.util.UUID;
import lombok.Data;

/** Represents an event */
@Data
public class Event {
  public Metadata details;
  public Map<String, Object> content;
  public String rawContent;
  public Map<String, Object> payload;

  public String eventId = UUID.randomUUID().toString();
}
