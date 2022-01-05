#Perceptual gambling task

### 1. Stage 1, `fix_perceptual`
The animal learns to fixate up to 1s, at the same time, it learns the mapping between two end sounds and the port sides. Variable block structure is used. Block lengths 10,15,20. 

Upgrade criterion: `nanmean(obj.hit) > 0.7`

### 2. Stage 2, `perceptual_cont`
The animal starts with `pitch_edge = 2`, and gradually progresses to `pitch_edge = 5` if their mean of `obj.hit` in a single session exceeds 0.7. See the table below for the list of sounds included in each pitch edge. Performance-based block structure is used. Block lengths 3,5,7,9. 

Upgrade criterion: `nanmean(obj.hit) > 0.7`



|Pitch edge| List of sounds (log2)|
|----------|---------------|
|2|[2,2.25,3.75,4]|
|3|[2,2.25,2.5,3.5,3.75,4]|
|4|[2,2.25,2.5,2.75,3.25,3.5,3.75,4]|
|5|random between [2,3) or (3,4]|

### Stage 3, `perceptual_rcont`
The animal now encounters the full range of the sounds, no block structure. 

Upgrade criterion: `nanmean(obj.hit) > 0.7`

### Stage 4, `hedging`
Light flashes appear with variable delays (0 to 300ms) after the poke initiation. It overlaps with the sound and lasts until the end of fixation. The side of light flashes is the 5x reward side if correct. Variable block structure for light flashes is used. Block lengths 10,13,15.

Manual promotion.

### Stage 5, `hedging_rand`
Similar to `hedging`, except that no block structure is present. This is the end stage of the protocol.

### Stage 6, `pg_auditory`
Despite being stage 6, this is not a more advanced stage than stage 5. It is a control task where instead of the light flashes, the speaker side now indicates the larger reward side. Note that there is NO delay between the perceptual and value cue now, as they are both present in the sound alone. Variable block structure for speaker side is used. Block lengths 10,13,15.

### Stage 7, `pg_auditory_rand`
Similar to `pg_auditory`, except that no block structure is present. 





 


