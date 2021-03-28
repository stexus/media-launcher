#!/usr/bin/env python3

import sys
from pathlib import Path
import requests
#todo:
#set timer for search so search only happens when stop typing done
#look through rofiftw to see how rofi blocks is used done
#look through rofi blocks examples done
#set up oauth custom url and queries in this python script (search, mutation)
#(done in lua) loop through anilist entries in json and determine which series is currently being updated based on episode number

#change to symlink; shouldn't be necessary because this isn't called anymore
parent_dir = Path(__file__).resolve().parent.parent
sys.path.insert(0, str(parent_dir))
from helpers.secrets import access_token
class Anilist:
    def __init__(self):
        self.url = 'https://graphql.anilist.co'
        self.curr_search = {}
        self.token = access_token
    def create_query(self, queryDict) -> str:
        return ''

    def _valid_response(self, json) -> bool:
        if 'errors' in json:
            print(json)
            return False
        return True
    def search(self, input) -> list[str]:
        if not input or len(input) == 1: return []
        query = '''
            query($search: String) {
                Page(page: 1, perPage: 7)  {
                    media(search: $search, type: ANIME) {
                        id
                        title {
                            romaji
                        }
                    } 
                }
            }
        '''
        variables = {
            'search': input
        }
        response = requests.post(self.url, json={'query': query, 'variables': variables})
        titles = self._get_titles(response.json()['data']['Page']['media'])
        return titles

    def _get_viewer(self) -> int:
        response = requests.post(self.url, json={'query': '{Viewer {id}}'}, headers={'Authorization': f'Bearer {access_token}'})
        return response.json()['data']['Viewer']['id']

    def _get_titles(self, media) -> list[str]:
        self.curr_search = {}
        titles = []
        for entry in media:
            title = entry['title']['romaji']
            #for sending to rofiblocks
            titles.append(title)
            self.curr_search[title] = entry['id']
        return titles

    def _get_progress(self, viewer, mediaId) -> int:
        query = '''
            query($userId: Int, $mediaId: Int) {
                MediaList(userId: $userId, mediaId: $mediaId, type: ANIME) {
                    progress
                    }
                }
        '''
        progress_response = requests.post(self.url, json={'query': query, 'variables': {'userId': viewer, 'mediaId': mediaId}})
        progress_response_json = progress_response.json()

        print(progress_response_json)
        if not self._valid_response(progress_response_json):
            #zero current progress
            return 0
        return progress_response_json['data']['MediaList']['progress']

    def _is_complete(self, mediaId, new_progress) -> bool:
        query = '''
            query($id: Int) {
                Media(id: $id, type: ANIME) {
                    episodes
                    }
                }
        '''
        #id here is for media, not for list
        response = requests.post(self.url, json={'query': query, 'variables': {'id': mediaId}})
        total_ep = response.json()['data']['Media']['episodes']
        return total_ep <= new_progress 

    def update_entry(self, id, episode=-1):
        #coming from command line as strings
        id = int(id)
        episode = int(episode)
        auth_header = {'Authorization': f'Bearer {self.token}'}
        query = '''
                mutation ($mediaId: Int, $status: MediaListStatus, $progress: Int) {
                    SaveMediaListEntry (mediaId: $mediaId, status: $status, progress: $progress) {
                            id
                            progress
                    }
                }
        '''
        viewer = self._get_viewer()
        #seeing if user input is reliable enough before falling back on increments of 1
        #new_progress = self._get_progress(viewer, id) + 1
        if episode < 0:
            episode = self._get_progress(viewer, id) + 1
        variables = {
            'mediaId': id,
            'status': 'COMPLETE' if self._is_complete(id, episode) else 'CURRENT',
            'progress': episode
        }
        response = requests.post(self.url, headers=auth_header, json={'query': query, 'variables': variables})
        return response.json()['data']['SaveMediaListEntry']['progress']

